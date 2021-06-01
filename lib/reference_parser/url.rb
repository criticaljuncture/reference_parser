class ReferenceParser::Url < ReferenceParser::Base
  BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }
  WORD_PATTERN = '\p{Word}'

  replace %r{
    (?<!("|'|//))
      (?<url>
        (?: (?<scheme>(?:http|https):)// | www.?\. )
        [^\s<\u00A0"]+
      )
    }ix 

  def default_link_classes
    "external"
  end

  def url(citation, url_options={})
    citation[:url] || "#{(url_options[:default_scheme] || "https")}://#{citation[:url_without_scheme]}"
  end

  def clean_up_named_captures(captures, options: {})
    url = captures[:url]
    punctuation = []
    # don't include trailing punctuation character as part of the URL
    while url&.sub!(/[^#{WORD_PATTERN}\/-=&]$/, '')
      punctuation.push $&
      if opening = BRACKETS[punctuation.last] and url.scan(opening).size > url.scan(punctuation.last).size
        url << punctuation.pop
        break
      end
    end
    link_text = url
    { (captures[:scheme] ? :url : :url_without_scheme) => url, text: link_text, suffix: punctuation.reverse.join }
  end
end
