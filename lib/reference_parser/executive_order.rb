class ReferenceParser::ExecutiveOrder < ReferenceParser::Base
  include ReferenceParser::Lists

  LIST_DIVIDER = ReferenceParser::Authority::COMMA_AND_OR_DIVIDER

  EO_LABEL = /
    \b
    E(?:xec(?:utive)?)?\.?\s*
    [O0](?:rd(?:ers?)?)?\.?
    (?:\s+No\.?)?
  /ix

  LABELED_EO_LABEL = /(?<eo_label>#{EO_LABEL})/io

  replace(
    /#{LABELED_EO_LABEL}\s*(?<eo_numbers>#{ReferenceParser::Authority::COMMA_NUMBER}(?:#{LIST_DIVIDER}#{ReferenceParser::Authority::COMMA_NUMBER})*)/io,
    pattern_slug: :executive_order
  )
  replace(/#{LABELED_EO_LABEL}\s+of\s+#{ReferenceParser::Authority.optional_date_pattern}/i, pattern_slug: :executive_order_dated)

  def url(citation, url_options = {})
    if citation[:eo_number] && (citation[:eo_number] >= 7_532)
      result = +""
      result << "https://www.federalregister.gov" if absolute?(url_options)
      result << "/executive-order/#{citation[:eo_number]}"
    end
  end

  def clean_up_named_captures(captures, options: {})
    label = captures.delete(:eo_label)
    raw = captures.delete(:eo_numbers)

    result = map_labeled_list(raw, divider: LIST_DIVIDER, label: label) do |num_str|
      eo_number = num_str&.delete(",")&.to_i || 0
      next {} if eo_number == 0

      {eo_number: eo_number, hierarchy: {eo_number: eo_number}}
    end

    return result if result.is_a?(Array)

    captures.merge!(result)
    ReferenceParser::Authority.clean_up_date_captures(captures, required: false)
    captures
  end

  def handles_lists
    true
  end

  def slug
    :eo
  end
end
