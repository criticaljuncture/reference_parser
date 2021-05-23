class ReferenceParser::Url < ReferenceParser::Base
  BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }
  WORD_PATTERN = '\p{Word}'

  replace %r{
      (?<url>
        (?: (?<scheme>(?:http|https):)// | www\. )
        [^\s<\u00A0"]+
      )
    }ix 

  def link_to(text, citation, options={})
    url = citation[:url]

    fr_image_url_prefix = Settings.cloudfront_fr_image_url

    if url.starts_with?(fr_image_url_prefix)
      url
    else
      punctuation = []

      # don't include trailing punctuation character as part of the URL
      while url.sub!(/[^#{WORD_PATTERN}\/-=&]$/, '')
        punctuation.push $&
        if opening = BRACKETS[punctuation.last] and url.scan(opening).size > url.scan(punctuation.last).size
          url << punctuation.pop
          break
        end
      end
      link_text = url

      url = 'http://' + url unless citation[:scheme]

      helpers.content_tag(:a, link_text, {href: url, class: "external"}) + punctuation.reverse.join('')
    end
  end
end
