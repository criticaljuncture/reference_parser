class ReferenceParser::Determination < ReferenceParser::Authority
  replace(/\bPresidential\s+Determination(?:\s+No\.?)?\s+(?<year>\d{4})-(?<determination_number>\d{1,4})\b/i, pattern_slug: :determination)

  def slug
    :determination
  end
end
