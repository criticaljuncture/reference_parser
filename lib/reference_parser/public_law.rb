class ReferenceParser::PublicLaw < ReferenceParser::Base
  replace /(?:Public Law|Pub\. Law|Pub\. L.|P\.L\.)\s+(?<congress>\d+)-(?<law>\d+)/i

  def url(citation, url_options={})
    if citation[:congress] >= 104
      "https://www.govinfo.gov/link/plaw/#{citation[:congress].to_i}/public/#{citation[:law].to_i}"
    end
  end

  def clean_up_named_captures(captures, options: {})
    captures[:congress] = captures[:congress]&.gsub(/,/, '')&.to_i || 0
  end

  def slug
    :publ
  end
end