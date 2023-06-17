class ReferenceParser::RegulatoryPlan < ReferenceParser::Base
  replace(/RIN\s(?<rin>[\dA-Z]{4}[-–—][\dA-Z]{4})/ix)

  def url(citation, url_options = {})
    if citation[:rin].present?
      result = ""
      result << "https://www.federalregister.gov" if absolute?(url_options)
      result << "/r/#{ReferenceParser::Dashes.ascii(citation[:rin])}"
    end
  end

  def slug
    :regulatory_plan
  end
end
