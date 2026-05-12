class ReferenceParser::Directive < ReferenceParser::Authority
  replace(
    /
      \b
      National\s*Security\s*
      (?:Council\s*|Decision\s*)?
      Directive\s*
      (?<directive_number>\d+)?
      (?:[“"”,\s]+(\w\s*)+[“"”,\s]+)?
      (?:signed\s*by\s*the\s*President\s*)?
      (?:of\s*|on\s*)?
      (?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*(?<year>[0-9]{4})
      \b
    /ixo,
    pattern_slug: :directive
  )

  def clean_up_named_captures(captures, options: {})
    month = month_index(captures[:month])
    year = captures[:year].to_i
    day = captures[:day].to_i
    unless month && Date.valid_date?(year, month, day)
      captures.clear
      return
    end
    captures[:date] = format("%04d-%02d-%02d", year, month, day)
  end

  def slug
    :directive
  end
end
