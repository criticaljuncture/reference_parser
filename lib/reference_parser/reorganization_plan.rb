class ReferenceParser::ReorganizationPlan < ReferenceParser::Authority
  replace(/\b(?<year>[0-9]{4})\s+Reorganization\s+Plan\s+No\.?\s+(?<plan_no>[0-9]+)\b/i, pattern_slug: :reorganization_plan)
  replace(/\bReorganization\s+Plan\s+No\.?\s+(?<plan_number>[0-9]+)\s+of\s+(?<year>[0-9]{4})\b/i, pattern_slug: :reorganization_plan_trailing)

  def clean_up_named_captures(captures, options: {})
    y = captures[:year].to_s
    n = captures[:plan_number].to_s
    captures[:reorganization_plan] = "#{y} Plan No. #{n}" if y.present? || n.present?
  end
end
