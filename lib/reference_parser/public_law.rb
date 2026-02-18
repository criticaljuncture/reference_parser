class ReferenceParser::PublicLaw < ReferenceParser::Base
  replace(/
    (?:
      P(?:ub(?:lic)?)?\.?\s*L(?:aw)?\.?
    )\s+(?<congress>\d+)[-–](?<law>\d+)
    /ix, pattern_slug: :public_law)

  FINAL_LAW_PER_SESSION = {
    118 => 274,
    117 => 362,
    116 => 334,
    115 => 442,
    114 => 329,
    113 => 296,
    112 => 283,
    111 => 383,
    110 => 460,
    109 => 482,
    108 => 498,
    107 => 377,
    106 => 580,
    105 => 394,
    104 => 333
  }

  RESPECT_KNOWN_SESSION_DETAILS = true

  def url(citation, url_options = {})
    if (congress = citation[:congress].to_i) >= 104 && (law = citation[:law].to_i)
      return if RESPECT_KNOWN_SESSION_DETAILS && !plausible(congress, law)
      "https://www.govinfo.gov/link/plaw/#{congress}/public/#{law}"
    end
  end

  def clean_up_named_captures(captures, options: {})
    captures[:congress] = captures[:congress]&.delete(",")&.to_i || 0
  end

  def slug
    :publ
  end

  private

  def plausible(congress, law)
    if (final = FINAL_LAW_PER_SESSION[congress])
      (law >= 1) && (law <= final)
    else
      true
    end
  end
end
