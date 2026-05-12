class ReferenceParser::PublicLaw < ReferenceParser::Base
  include ReferenceParser::Lists

  PUBLIC_LAW_NUMBER = /\d+[-–]\d+/
  LIST_DIVIDER = ReferenceParser::Authority::SEMICOLON_COMMA_AND_OR_DIVIDER

  LABELED_PL_LABEL = /(?<pl_label>#{ReferenceParser::Cfr::PL_LABEL})/io

  replace(
    /#{LABELED_PL_LABEL}\s*(?<public_laws>#{PUBLIC_LAW_NUMBER}(?:#{LIST_DIVIDER}#{PUBLIC_LAW_NUMBER})*)/io,
    pattern_slug: :public_law,
    will_consider_pre_match: true,
    will_consider_post_match: true
  )

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
    # Skip when Pub. L. only labels Act sections that are parenthetically USC-mapped:
    #   "sec. 212, Pub. L. 93-66, 87 Stat. 155 (42 U.S.C. 1382 note)"
    # Keep peer Pub. L. authorities (even with Stat / USC note):
    #   "and Pub. L. 107-43, 115 Stat. 243 (19 U.S.C. 2112 note)"
    #   "Pub. L. 107-609, 115 Stat. 1012; Pub. L. 107-296, 116 Stat. 2135 (6 U.S.C. 101 note)"
    if options[:post_match]&.match?(/\A\s*,\s*\d+\s+Stat\.\s+[\d,\sand]+\s*\(\s*\d+\s+U\.?S\.?C/i) &&
        options[:pre_match]&.match?(/[\d)][a-z0-9().-]*,\s*\z/i)
      return :skip
    end

    label = captures.delete(:pl_label)
    raw = captures.delete(:public_laws)

    result = map_labeled_list(raw, divider: LIST_DIVIDER, label: label) do |num_str|
      next {} unless (match = num_str&.match(/(\d+)[-–](\d+)/))

      {congress: match[1].delete(",").to_i, law: match[2].delete(",")}
    end

    return result if result.is_a?(Array)

    captures.merge!(result)
    captures
  end

  def handles_lists
    true
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
