class ReferenceParser::Url < ReferenceParser::Base
  BRACKETS = "[](){}".chars.each_slice(2).map(&:reverse).to_h
  WORD_PATTERN = '\p{Word}'

  replace(%r{
    (?<!(?:"|'|//))
      (?<url>
        (?: (?<scheme>(?:http|https):)// | www.?\. )
        [^\s<\u00A0"]+
      )
    }ix, pattern_slug: :url)

  def default_link_classes
    "external"
  end

  def url(citation, url_options = {})
    citation[:url] || "#{url_options[:default_scheme] || "http"}://#{citation[:url_without_scheme]}"
  end

  def clean_up_named_captures(captures, options: {})
    url = captures[:url]
    punctuation = []
    # don't include trailing punctuation character as part of the URL
    while url&.sub!(/[^#{WORD_PATTERN}\/-=&]$/o, "")
      punctuation.push $&
      if (opening = BRACKETS[punctuation.last]) && (url.scan(opening).size > url.scan(punctuation.last).size)
        url << punctuation.pop
        break
      elsif punctuation.last == "-" && punctuation.count > 1
        url << punctuation.pop
        break
      end
    end
    link_text = url
    {(captures[:scheme] ? :url : :url_without_scheme) => url, :text => link_text, :suffix => punctuation.reverse.join}
  end
end
