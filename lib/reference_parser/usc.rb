class ReferenceParser::Usc < ReferenceParser::Base
  USC_LABEL = /U(nited)?\.?\s*S(tates)?\.?\s*C(ode)?\.?/ix

  replace(/section\s*(?<section>\d+)\s*of\s*title\s*(?<title>\d+),?\s*#{USC_LABEL}/ixo)
  replace(/chapter\s*(?<chapter>\d+)\s*of\s*title\s*(?<title>\d+),?\s*#{USC_LABEL}/ixo)

  def url(citation, url_options = {})
    return unless citation&.slice(%(title part))&.all?(&:present?)
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{citation[:part]}"
  end

  def clean_up_named_captures(captures, options: {})
    puts "ReferenceParser::Usc clean_up_named_captures captures #{captures}" if @debugging
    captures.reverse_merge!(captures[:href_hierarchy] || captures[:hierarchy]) if captures[:href_hierarchy].present? || captures[:hierarchy].present?
    captures[:part] = captures[:section] if !captures[:part] && captures[:section]
    captures[:part] = captures[:chapter] + "01" if !captures[:part] && captures[:chapter]
    captures[:part] = captures[:part].partition("(").first if captures[:part]&.include?("(")
  end

  def depends_on_parser
    :cfr
  end

  def slug
    :usc
  end
end
