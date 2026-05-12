class ReferenceParser::Proclamation < ReferenceParser::Authority
  PROCLAMATION_LABEL = /
    \b
    (?:Presidential\s+)?
    Proc(?:lamation)?\.?
    (?:\s+No\.?)?
  /ix

  replace(
    /#{PROCLAMATION_LABEL}\s*(?<proclamation_number>#{COMMA_NUMBER})(?:\s+of\s+#{optional_date_pattern})?/io,
    pattern_slug: :proclamation
  )

  def clean_up_named_captures(captures, options: {})
    captures.delete(:proclamation_label)
    if captures[:proclamation_number]
      captures[:proclamation_number] = captures[:proclamation_number].delete(",").to_i
    end
    super
    captures
  end

  def slug
    :proclamation
  end
end
