class ReferenceParser::Notice < ReferenceParser::Authority
  replace(/\bNotice\s+of\s+#{date_pattern}\b/i, pattern_slug: :notice)

  def slug
    :notice
  end
end
