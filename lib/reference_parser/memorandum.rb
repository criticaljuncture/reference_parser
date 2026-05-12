class ReferenceParser::Memorandum < ReferenceParser::Authority
  replace(/\bMemorandum\s+of\s+the\s+President\s+for\s+Heads\s+of\s+Departments\s+and\s+Agencies\s+\((?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*(?<year>[0-9]{4})\)/i, pattern_slug: :memo)
  replace(/\bPresidential\s+Memorandum\s+of\s+(?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*(?<year>[0-9]{4})\b/i, pattern_slug: :memo)

  def clean_up_named_captures(captures, options: {})
    month = month_index(captures[:month])
    year = captures[:year].to_i
    day = captures[:day].to_i
    unless month && Date.valid_date?(year, month, day)
      captures.clear
      return
    end
    captures[:date] = format("%04d-%02d-%02d", year, month, day)
    captures.delete(:month)
    captures.delete(:day)
    captures.delete(:year)
  end

  def slug
    :memorandum
  end
end
