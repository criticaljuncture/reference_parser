class ReferenceParser::Directive < ReferenceParser::Authority
  # after an optional number: either a quoted title, or comma/space before the date
  TITLE_OR_DATE_SEPARATOR = /(?:,\s*[“"][^”"]+[”"],?\s*|[,\s]+)/

  replace(
    /
      \b
      (?:National\s*Security\s*|Presidential\s*|Information\s*Security\s*Oversight\s*)?
      (?:Council\s*|Decision\s*)?
      Directive\s*
      (?:No\.\s*)?
      (?<directive_number>\d+)?
      #{TITLE_OR_DATE_SEPARATOR}?
      (?:signed\s*by\s*the\s*President\s*)?
      (?:of\s*|on\s*)?
      #{date_pattern}
      \b
    /ixo,
    pattern_slug: :directive
  )

  def slug
    :directive
  end
end
