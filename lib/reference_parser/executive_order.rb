class ReferenceParser::ExecutiveOrder < ReferenceParser::Base
  replace(/(?:\bE\.\s*O\.|\bE\s*O\b|\bExecutive Order\b)(?:\s+No\.?)?\s+(?<eo_number>[0-9,]+)/i, pattern_slug: :executive_order)

  def url(citation, url_options = {})
    if citation[:eo_number] >= 7_532
      result = +""
      result << "https://www.federalregister.gov" if absolute?(url_options)
      result << "/executive-order/#{citation[:eo_number]}"
    end
  end

  def clean_up_named_captures(captures, options: {})
    captures[:eo_number] = captures[:eo_number]&.delete(",")&.to_i || 0
  end

  def slug
    :eo
  end
end
