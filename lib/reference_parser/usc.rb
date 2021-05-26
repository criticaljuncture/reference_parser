class ReferenceParser::Usc < ReferenceParser::Base
  replace /(?<title>\d+)\s+U\.?S\.?C\.?\s+(?<part>\d+)/i

  replace /section (?<section>\d+) of title (?<title>\d+), United States Code/i
  replace /chapter (?<chapter>\d+) of title (?<title>\d+), United States Code/i

  def url(citation, url_options={})
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{citation[:part]}"
  end

  def clean_up_named_captures(captures, options: {})
    captures[:part] = captures[:section] if !captures[:part] && captures[:section]
    captures[:part] = captures[:chapter] + "01" if !captures[:part] && captures[:chapter]
  end

  def slug
    :usc
  end
end
