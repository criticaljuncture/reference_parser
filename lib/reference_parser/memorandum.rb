class ReferenceParser::Memorandum < ReferenceParser::Authority
  replace(/
    \b
    (?:President(?:ial|'s)\s+)?
    Memorandum\s+
    (?:
      of\s+ |
      dated\s+ |
      entitled\s+[“"][^”"]+[”"],\s+issued\s+ |
      of\s+the\s+President\s+for\s+Heads\s+of\s+Departments\s+and\s+Agencies\s+ |
      to\s+.+?,\s*3\s*CFR\s*p\.\s*\d+\s*
    )
    \(?
    #{optional_date_pattern}
    \)?
  /ix, pattern_slug: :memo)

  replace(/\b(?<memorandum>Pres\.\sMem\.)/i, pattern_slug: :memo_unspecified)

  def slug
    :memorandum
  end
end
