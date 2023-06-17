class ReferenceParser::DfarsPgi < ReferenceParser::Base
  replace(/PGI\s*(?<page>\d{3}\.\d)(?<anchor_suffix>[\d\-–—]*)/ix)

  def url(citation, url_options = {})
    if citation[:page].present?
      anchor_suffix = ReferenceParser::Dashes.ascii(citation[:anchor_suffix])
      "https://www.acq.osd.mil/dpap/dars/dfars/html/current/#{citation[:page].tr(".", "_")}.htm#{anchor_suffix ? "##{citation[:page]}#{anchor_suffix}" : ""}"
    end
  end

  def slug
    :dfars_pgi
  end
end
