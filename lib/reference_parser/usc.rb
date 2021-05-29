class ReferenceParser::Usc < ReferenceParser::Base
  replace /(?<title>\d+)\s+U\.?S\.?C\.?\s+(§\s*)?(?<part>\d+(\([a-z\d]\))*([a-z\d])*)/ix

  replace /section\s*(?<section>\d+)\s*of\s*title\s*(?<title>\d+),?\s*U(nited)?\.?\s*S(tates)?\.?\s*C(ode)?\.?/ix
  replace /chapter\s*(?<chapter>\d+)\s*of\s*title\s*(?<title>\d+),?\s*U(nited)?\.?\s*S(tates)?\.?\s*C(ode)?\.?/ix

  def url(citation, url_options={})
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{citation[:part]}"
  end

  def clean_up_named_captures(captures, options: {})
    captures[:part] = captures[:section] if !captures[:part] && captures[:section]
    captures[:part] = captures[:chapter] + "01" if !captures[:part] && captures[:chapter]
    captures[:part] = captures[:part].partition("(").first if captures[:part].include?("(")
  end

  def slug
    :usc
  end
end
