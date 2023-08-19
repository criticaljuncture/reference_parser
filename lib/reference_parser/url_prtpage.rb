require "htmlentities"

class ReferenceParser::UrlPrtpage < ReferenceParser::Base
  extend ActionView::Helpers::TagHelper

  BRACKETS = "[](){}".chars.each_slice(2).map(&:reverse).to_h
  WORD_PATTERN = '\p{Word}'
  AUTO_LINK_RE = %r{
    (?<initial_href>(?: (?<scheme>(?:http|https):)// | www\d?\. )
    [^\s<\u00A0"]*)
    (?:
      (?<page_break>\s*<PRTPAGE\s+P="\d+"/>\s*)
      (?<final_fragment>[^\s<\u00A0"]+)
    )?
    (?<href_ending_with_spaces>
      \s                           # space at the end of the url proper
      (?:\w{1,32}[\s-]?){1,8}     # up to 8 additional fragments seperated by a single space
      \s?                          # optional space
      (?:.(?:pdf|html?|aspx?|txt)) # required suffix to allow spaces
    )?                             # optionally link url-ish text with spaces
  }ix

  replace(AUTO_LINK_RE, will_consider_pre_match: true, will_consider_post_match: true)

  def default_link_classes
    "external"
  end

  def url(citation, url_options = {})
    citation[:url] || (citation[:url_without_scheme] ? "#{url_options[:default_scheme] || "http"}://#{citation[:url_without_scheme]}" : nil)
  end

  def clean_up_named_captures(captures, options: {})
    # link_attributes = {"target" => "_blank", "rel" => "noopener noreferrer"}
    coder = HTMLEntities.new(:expanded)

    initial_href = captures[:initial_href]
    scheme = captures[:scheme]
    page_break = captures[:page_break]
    final_fragment = captures[:final_fragment]
    href_ending_with_spaces = captures[:href_ending_with_spaces]
    punctuation = []

    initial_href = coder.decode(initial_href)
    final_fragment = coder.decode(final_fragment)

    href = if final_fragment.present?
      initial_href + final_fragment
    else
      initial_href
    end

    results = []

    html = [initial_href, page_break, final_fragment].compact.join
    if %w[http:// https://].include?(initial_href) && final_fragment.blank?
      results << {result: html}
    else
      # don't include trailing punctuation character as part of the URL
      while href.sub!(/[^#{WORD_PATTERN}\/\-=&;]$/o, "")
        punctuation.push $&
        if (opening = BRACKETS[punctuation.last]) && (href.scan(opening).size > href.scan(punctuation.last).size)
          href << punctuation.pop
          break
        end
      end

      href = "http://" + href unless scheme
      href = (href + href_ending_with_spaces).gsub(" ", "%20") if href_ending_with_spaces.present?
      trailing_link_content = href_ending_with_spaces || ""
      trailing_punctuation = punctuation.reverse.join

      if href.end_with?(";") && (href.count("?") == 0)
        initial_href.delete_suffix!(";")
        href.delete_suffix!(";")
        trailing_punctuation = ";" + (trailing_punctuation || "")
      end

      if final_fragment.present?
        final_fragment.sub!(/#{Regexp.escape(trailing_punctuation)}\z/, "")

        results << {url: href, text: ReferenceParser::UrlPrtpage.add_line_break_indicators(initial_href)}
        results << {result: page_break.html_safe}
        results << {url: href, text: ReferenceParser::UrlPrtpage.add_line_break_indicators(final_fragment + trailing_link_content), suffix: trailing_punctuation}
      else
        results << {url: href, text: ReferenceParser::UrlPrtpage.add_line_break_indicators(initial_href + trailing_link_content), suffix: trailing_punctuation}
      end
    end

    results
  end

  def link_to(text, citation, options = {})
    return citation[:result] if citation[:result]
    super
  end

  def self.add_line_break_indicators(url_fragment)
    # ?! moved along with specs expecting from FR Hyperlinker::Url
    fragment = url_fragment.gsub(/(?<!:)(?<!\/)([_;&\/?=+])/, "\\1\u200B")

    HTMLEntities.new.encode(fragment, :named, :decimal).html_safe
  end
end
