class ReferenceParser::Usc < ReferenceParser::Base
  replace(/section\s*(?<section>\d+)\s*of\s*title\s*(?<title>\d+),?\s*#{ReferenceParser::Cfr::USC_LABEL}/ixo)
  replace(/chapter\s*(?<chapter>\d+)\s*of\s*title\s*(?<title>\d+),?\s*#{ReferenceParser::Cfr::USC_LABEL}/ixo)
  replace(/(?<irc_label>#{ReferenceParser::Cfr::IRC_LABEL})(?<section_label>\s*§\s*|\s*section\s*)(?<section>\d+[a-z]?)\b/ixo) # I.R.C. § 6212

  def url(citation, url_options = {})
    return unless citation&.values_at(:title, :part)&.all?(&:present?)
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{citation[:part]}"
  end

  def clean_up_named_captures(captures, options: {})
    puts "ReferenceParser::Usc clean_up_named_captures captures #{captures}" if @debugging
    captures.reverse_merge!(captures[:href_hierarchy] || captures[:hierarchy]) if captures[:href_hierarchy].present? || captures[:hierarchy].present?
    captures[:title] = "26" if !captures[:title] && captures[:irc_label].present?
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
