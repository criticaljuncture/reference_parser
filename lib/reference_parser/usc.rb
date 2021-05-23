class ReferenceParser::Usc < ReferenceParser::Base
  replace /(?<title>\d+)\s+U\.?S\.?C\.?\s+(?<part>\d+)/i

  def url(citation, url_options={})
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{citation[:part]}"
  end

  def slug
    :usc
  end
end
