class ReferenceParser::ReorganizationPlan < ReferenceParser::Authority
  LIST_DIVIDER = SEMICOLON_COMMA_AND_OR_DIVIDER

  REORG_LABEL = /(?:Reorganization|Reorgan\.|Reorg\.?)/ix
  REORGANIZATION_PLAN_LABEL = /#{REORG_LABEL}\s+Plan\b/ix
  REORGANIZATION_PLANS_LABEL = /#{REORG_LABEL}\s+Plans\b/ix
  PLAN_NUMBER_LABEL = /N(?:o\.?|umber)/
  PLAN_OF_YEAR = /\s*(?:,\s*)?of\s+(?<year>[0-9]{4})/
  PLAN_CFR_CITATION = /\s*\(\s*3\s+CFR,\s*(?<year>[0-9]{4})\s+Comp\./
  PLAN_YEAR = /(?:#{PLAN_OF_YEAR}|#{PLAN_CFR_CITATION})/
  PLAN_ENTRY = /#{PLAN_NUMBER_LABEL}\s+[0-9]+#{PLAN_OF_YEAR}(?:\s*\([^)]+\))?/

  LABELED_REORGANIZATION_PLANS_LABEL = /(?<reorganization_plan_label>#{REORGANIZATION_PLANS_LABEL})/io

  replace(
    /#{LABELED_REORGANIZATION_PLANS_LABEL}\s+(?<reorganization_plans>#{PLAN_ENTRY}(?:#{LIST_DIVIDER}#{PLAN_ENTRY})*)/io,
    pattern_slug: :reorganization_plan_list
  )
  replace(/\b(?<year>[0-9]{4})\s+#{REORGANIZATION_PLAN_LABEL}\s+#{PLAN_NUMBER_LABEL}\s+(?<plan_number>[0-9]+)\b/io, pattern_slug: :reorganization_plan)
  replace(/\b#{REORGANIZATION_PLAN_LABEL}\s+#{PLAN_NUMBER_LABEL}\s+(?<plan_number>[0-9]+)#{PLAN_YEAR}/io, pattern_slug: :reorganization_plan_trailing)

  def clean_up_named_captures(captures, options: {})
    return captures unless captures[:reorganization_plans]

    label = captures.delete(:reorganization_plan_label)
    raw = captures.delete(:reorganization_plans)
    plan_strings, dividers = split_list_parts(raw, divider: LIST_DIVIDER)
    return captures if plan_strings.empty?

    entries = if plan_strings.size <= 1
      parsed = parse_plan_entry(plan_strings.first)
      return captures unless parsed.present?

      [parsed]
    else
      build_list_citations(label, plan_strings, dividers) { |plan_str| parse_plan_entry(plan_str) }
    end

    entries.flat_map do |entry|
      embedded = entry.delete(:embedded_stat)
      embedded ? [entry, embedded] : [entry]
    end
  end

  def handles_lists
    true
  end

  def slug
    :reorganization_plan
  end

  private

  def parse_plan_entry(raw)
    return unless raw.present?

    embedded = ReferenceParser::Stat.embedded_from_parenthetical(raw)
    plan_core = raw.sub(ReferenceParser::Stat::TRAILING_STAT_PAREN, "")
    match = plan_core.match(/#{PLAN_NUMBER_LABEL}\s+(?<plan_number>[0-9]+)#{PLAN_YEAR}/io)
    return unless match

    result = {plan_number: match[:plan_number], year: match[:year]}
    result[:embedded_stat] = embedded if embedded
    result
  end
end
