class ReferenceParser::FederalRegister < ReferenceParser::Base
  def url(citation, url_options = {})
    return unless citation&.values_at(:volume, :page)&.all?(&:present?)
    result = ""
    result << "https://www.federalregister.gov" if absolute?(url_options)
    result << "/citation/#{citation[:volume]}-FR-#{ReferenceParser::Dashes.ascii(citation[:page])}"
  end

  def link_options(citation)
    {class: "fr-reference", "data-reference": "#{citation[:volume]} FR #{ReferenceParser::Dashes.ascii(citation[:page])}"}
  end

  def clean_up_named_captures(captures, options: {})
    captures.reverse_merge!(captures[:hierarchy]) if captures[:hierarchy].present?
    captures[:volume] = captures[:title] if !captures[:volume] && captures[:title]
    captures[:page] = captures[:section] if !captures[:part] && captures[:section]
    captures[:page] = captures[:chapter] if !captures[:part] && captures[:chapter]
    captures[:page] = captures[:part].partition("(").first if captures[:part]&.include?("(")
    captures[:page] = captures[:page].split("-")[0] if captures[:page]&.include?("-")
    captures[:page] = captures[:page].split("–")[0] if captures[:page]&.include?("–")
    captures[:page] = captures[:page].split("—")[0] if captures[:page]&.include?("—")
  end

  def depends_on_parser
    :cfr
  end

  def slug
    :federal_register
  end

  def handles_lists
    true
  end
end
