class ReferenceParser::Notice < ReferenceParser::Authority
  replace(/\bNotice\s+of\s+(?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*(?<year>[0-9]{4})\b/i, pattern_slug: :notice)

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
    :notice
  end
end
