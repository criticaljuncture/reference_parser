class ReferenceParser::FederalRegister < ReferenceParser::Base
  replace /(?<volume>\d+)\s+FR\s+(?<page>\d+)/

  def url(citation, url_options={})
    return unless citation
    result = ""
    result << "https://www.federalregister.gov" if absolute?(url_options)
    result << "/citation/#{citation[:volume]}-FR-#{citation[:page]}"
  end

  def link_options(citation)
    {class: "fr-reference", :"data-reference" => citation[:text]}
  end
end
