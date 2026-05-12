class ReferenceParser::Cfr < ReferenceParser::Base
  MAX_EXPECTED_CFR_TITLE = 50
  MAX_EXPECTED_FR_TITLE = 999

  include ReferenceParser::CfrAliases

  def link_options(citation)
    {class: "cfr external"}
  end

  # sub-patterns & utilities

  TITLE_ID = /\d+/
  SUBTITLE_ID = /(?:[A-Z]{1,7})/ix
  CHAPTER_ID = /[IVXLCDM0-9]+/ix
  SUBCHAPTER_ID = /[A-Z]+[-–—_]?[A-Z]*/ix
  PART_ID = /\w+[-–—]?\w*/ix
  SUBPART_ID = /\w{1,4}(?:[\w.\-–—]{0,5}(?:\w|(?:suspended)))?\b/ix # constraint /\w+[\w.\-–—]*\w*/ix generated/internal ECFR[0-9A-Z]{15,16}
  SUBPART_ID_ADDITIONAL = /\w{1,4}([.\-–—][\w.\-–—]{0,5}|)(?:suspended)?\b/ix
  SECTION_ID = /[\w\-–—]+.?[\w\-–—()]*/ix

  CFR_LABEL = /C(?:ode(?:\s*of)|\.)?\s*F(?:ederal|\.)?\s*R(?:egulations|\.)?/ix
  USC_LABEL = /U(?:nited)?\.?\s*S(?:tates)?\.?\s*C(?:ode)?\.?(?:\s*\(IRC\))?/ix
  USC_CITATION_CONTEXT = /\d+(?:\.|\s)\s*U\.?S\.?C(?!\.?A\b)/i
  LIST_CONTINUATION_BLOCK_BOUNDARY = /<\/(?!(?:em|i)\b)[^>]+>/i
  IRC_LABEL = /I(?:nternal)?\.?\s*R(?:evenue)?\.?\s*C(?:ode)?\.?/ix
  FR_LABEL = /F(?:ederal)?\.?\s*R(?:egister)?\.?/ix
  PL_LABEL = /
    P(?:ub(?:lic)?)?\.?\s*
    L(?:aw)?s?\.?\s*
    (?:No\.?\s*)?
  /ix

  SOURCE_LABEL = /(?<source_label>\.?\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL})\s*)/ixo
  SOURCE_LABEL_CFR = /(?<source_label>\.?\s*#{CFR_LABEL}\s*)/ixo
  SOURCE_LABEL_NON_CFR = /(?<source_label>\.?\s*(?:#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL})\s*)/ixo

  SOURCE_LABEL_ALLOW_SHORTHAND = /(?<source_label>\.?\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL}|\/)\s*)/ixo
  SOURCE_LABEL_ALLOW_SHORTHAND_CFR = /(?<source_label>\.?\s*(?:#{CFR_LABEL}|\/)\s*)/ixo

  TITLE_SOURCE = /(?:Title\s*)?(?<title>#{TITLE_ID})#{SOURCE_LABEL}/ixo
  TITLE_SOURCE_CFR = /(?<title>#{TITLE_ID})#{SOURCE_LABEL_CFR}/ixo

  TITLE_SOURCE_ALLOW_SLASH_SHORTHAND = /
    (?<title>#{TITLE_ID})
    #{SOURCE_LABEL_ALLOW_SHORTHAND}
    /ixo

  TITLE_SOURCE_ALLOW_SLASH_SHORTHAND_CFR = /
    (?<title>#{TITLE_ID})
    #{SOURCE_LABEL_ALLOW_SHORTHAND_CFR}
    /ixo

  # "1 CFR 11 and 2 CFR 22" vs "1 CFR 11 and 12" needed after
  # simple digits patterns that could match the next title
  NEXT_TITLE_STOP = /
    (?!\d|
      [A-Za-z]\s*Stat\.?|
      \s*(?:
        C\.?F\.?R| # CFR
        U\.?S\.?C| # USC
        F\.?R\.?(?!\w)|  # FR
        I\.?R\.?C| # IRC
        Comp\.|
        Stat\.?|
        ,?\s*subpart|
        \/         # dates
    ))/ix

  TRAILING_BOUNDRY = /(?!\.?\d|\/)/ix # don't stop mid-number or date

  JOIN = /
    \s*
      (?!CFR)
      (?:
        ,(?:\s*and\s*)? |
        (?:,\s*)?and\b |
        (?:,\s*|)or\b |
        through
      )
    \s*
  /ixo

  LOOSE_SECTION_SAFE_JOINS = /
    , |
    ; |
    (?:[,;]\s*|)and\b |
    (?:,\s*|)or\b |
    (?<!note\s)to\b |
    through\s*
    /ixo

  LOOSE_SECTION_JOIN_SECTION = /
    \s*
      (?!CFR)
      (?:
        #{LOOSE_SECTION_SAFE_JOINS}
      )
    \s*
    /ixo

  JOIN_SECTION = /
    \s*
      (?!CFR)
      (?:
        #{LOOSE_SECTION_SAFE_JOINS} |
        and(?:\s*parts?\s*|\s*§+\s*)?
      )
    \s*
    /ixo

  SUBTITLE_LABEL = /(?<subtitle_label>subtitle\s*)/ix
  SUBTITLE = /(?<subtitle>[A-Z])/ix
  CHAPTER_LABEL = /(?<chapter_label>\s*Ch(?:ap(?:ter)?|\.)?\s*)/ix
  CHAPTER = /(?<chapter>#{CHAPTER_ID})/ixo
  SUBCHAPTER_LABEL = /(?<subchapter_label>\s*Subch(?:ap(?:ter)?)?\s*)/ix
  SUBCHAPTER = /(?<subchapter>#{SUBCHAPTER_ID})/ixo

  SUBPART_LABEL = /(?<subpart_label>[,:]?\s*su[pb]{2}arts?\s*)/ix
  SUBPART = /(?<subpart>#{SUBPART_ID})/ixo

  SUBPARTS = /
    (?<subparts>
      #{SUBPART_ID}
      (?:
        (?:#{JOIN})
        (?!(?:and|or)\b)
        (?!\s*\d+\s*(?:(?:Apps?\.?|Appendix)\s*)?U\.?S\.?C)
        #{SUBPART_ID_ADDITIONAL}
      )*
    )
    /ixo

  PART_LABEL = /(?<part_label>\s*Part\s*)/ix
  PART = /(?<part>#{PART_ID})/ixo
  PARTS = /
    (?<parts>
      (?:
        (?:\s|,|and(?:\s*parts?\s*)?|or|through|-|(?:\s*part\s*))+
        (?:\d+)
      )+
    )
    /ixo

  PARENTHETICALS = /
  (?: \((?:<em>)?[a-z]{1,3}(?:<\/em>)?\)\s* | # a b c
      \((?:<em>)?\d{1,3}(?:<\/em>)?\)\s*    | # 1 2 3
      \((?:<em>)?[xvi]{1,7}(?:<\/em>)?\)\s*   # i ii iii
  )
  /ix

  OPTIONAL_PARENTHETICALS = /#{PARENTHETICALS}*/ixo

  PARAGRAPH_UNLABELED = /\s*#{PARENTHETICALS}*(-\d+)?/ixo
  PARAGRAPH_UNLABELED_REQUIRED = /\s*#{PARENTHETICALS}+(-\d+)?/ixo

  # entire value is a single lettered paragraph ie "(a)"
  LONE_PARAGRAPH = /\A\([a-z]{1,5}\)\z/i

  PARAGRAPH = /(?<paragraph>#{PARAGRAPH_UNLABELED})/ixo

  PARAGRAPHS = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        #{PARAGRAPH_UNLABELED_REQUIRED}
        (?:
          (?:\s|,|and|or|through)+
          #{PARAGRAPH_UNLABELED_REQUIRED}
        )*
      )
    )
    /ixo

  PREFIXED_PARAGRAPHS = /
  (?<prefixed_paragraphs>                          # list of paragraphs
    (?:
      (?:\s*and\s*)?
      #{PARAGRAPH_UNLABELED_REQUIRED}
    )*
  )
  /ixo

  POTENTIAL_LISTED_SECTION = /
      \d+\.\d+(?:[-–—]\d+)?T?
    /ixo

  PARAGRAPHS_OPTIONAL_LIST = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|;|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELED_REQUIRED}|#{POTENTIAL_LISTED_SECTION}(?:\s+introductory\s+text\b)?)
        (?:
          [a-z]\d?-\d+[a-z]?
        )?
      )*
    )
    /ixo

  EXAMPLES = /
    (?:
      (?:<em>)?\s*Examples?\s*\d+(?:<\/em>)?(?:\s*through\s*|\s*,\s*(?:and\s*)?)?      # Example 28, Example 29, and Example 30
    )+
    /ix

  # lists of paragraphs w/ examples
  EXPANDED_PARAGRAPHS = /
    (?<paragraph_prefix>
      \s*and\s*
      #{EXAMPLES}
      \s*in\s*paragraph\s*
    )?
    (?<paragraphs>                                    # list of paragraphs
        (?:(?:\s+|,|and|or|through|\s\(last\ssentence\))+#{PARENTHETICALS}+(-\d+)?)*
    )
    /ixo

  # 240.15c3-1e(a)(1)(viii)(G)
  # 165.T07-0806

  SECTION_UNLABELED = /
    \d+#{NEXT_TITLE_STOP}(?:\.\d+)?#{NEXT_TITLE_STOP}(?:[a-z]{1,3}\d?)?
    #{OPTIONAL_PARENTHETICALS}
    (?:
      [a-z]\d+-\d |
      [-–—]\d+T?[a-z]? | # dash suffix if present tends to mark end of section area
      \.T\d{,2}[-–—]\d{,6} |
      \.\d+  |
      \(T\)    # temporary may be marked w T suffix
    )*

    \s*#{NEXT_TITLE_STOP}
    /ixo

  SECTION = /(?<section>#{SECTION_UNLABELED})/ixo

  SECTIONS = /
    (?<sections>
      (?:
        (?:#{JOIN_SECTION})?
        #{SECTION_UNLABELED}                         # additional sections
      )+
    )
    /ixo

  SECTION_NOTE_TO_TARGET = /
    (?:
      <em>[^<]*<\/em> |
      [^,;]+?
    )
  /ixo

  SECTION_TRAILING_MODIFIER = /
    (?:
      \s+notes?\s+to\s+#{SECTION_NOTE_TO_TARGET} |
      \s+introductory\s+text\b |
      (?<!preceding\s)\s+notes?\b(?!\s+(?:prec\.?|to\b))
    )
  /ixo

  SECTION_TRAILING_MODIFIER_OPTIONAL = /(?:#{SECTION_TRAILING_MODIFIER})?/ixo

  LOOSE_SECTION_CORE = /
    \d+#{NEXT_TITLE_STOP}(?:\.\d+)?#{NEXT_TITLE_STOP}(?:[a-z]{1,3}\d?)?
    #{OPTIONAL_PARENTHETICALS}
    (?:
      [a-z]\d+-\d |
      [-–—]\d+T?[a-z]? |
      \.T\d{,2}[-–—]\d{,6} |
      \.\d+  |
      \(T\)
    )*
  /ixo

  LOOSE_SECTION_ITEM = /
    #{LOOSE_SECTION_CORE}
    #{SECTION_TRAILING_MODIFIER_OPTIONAL}
    \s*#{NEXT_TITLE_STOP}
  /ixo

  LOOSE_SECTION_SECTIONS = /
    (?<sections>
      (?:
        (?:#{LOOSE_SECTION_JOIN_SECTION})?
        #{LOOSE_SECTION_ITEM}
      )+
    )
  /ixo

  APPENDIX_ID = /[A-Z]+/ixo
  APPENDIX_ROMAN_ID = "[IVXLC]{1,8}"
  APPENDIX_SECTION_ID = "(?:\\d|#{APPENDIX_ROMAN_ID})"
  PART_APPENDIX_LABEL = "(?:Appendix|Apps?|Ap)\\.?"
  # optional markers between App. and section number: "App. §§ 2061", "App § 468", "App. P. 534"
  APPENDIX_SECTION_MARKERS = "(?:(?:§+|P\\.)\\s*)?"
  PRECEDING_NOTE_LABEL = "note\\s+prec\\.?"
  USC_SECTION_LETTER_SUFFIX = "(?:(?!nt\\b)[a-z]{1,5}(?![a-z])|\\s+(?!and\\b|or\\b|to\\b|et\\b|as\\b|of\\b|by\\b|in\\b|on\\b|at\\b|for\\b)(?!nt\\b)[a-z]{1,2}(?![a-z])(?=\\s*[,;)]|\\.(?![a-z])|\\s+(?:and|or|&)\\b|\\s*$))"
  USC_SECTION_EM_LETTER_SUFFIX = "(?:<em>(?:(?!nt\\b)[a-z]{1,5}(?:[,.])?)?</em>)?"
  # "77f", "78o-4", "1395.1" — section number w/ optional decimal & letter suffix (not "12a34" artifacts)
  LAX_USC_SECTION_NUMBER = "(?>\\d+)(?![a-z]+\\d)(?:\\.\\d+)?#{USC_SECTION_LETTER_SUFFIX}?"
  LAX_USC_SECTION_RANGE = "(?:[-–—](?:\\d+(?:\\.\\d+)?(?:[a-z]{1,5})?|[a-z]{1,5})(?:[-–—][a-z]{1,5})*)?"
  APPENDIX_ROMAN_SECTION = "(?>(?-i:#{APPENDIX_ROMAN_ID}))(?=\\s|[.,;)-]|$)"
  PART_APPENDIX_PRECEDING_NOTE_WITH_SECTION = "(?<part_appendix_label>\\s*#{PART_APPENDIX_LABEL}\\s+#{PRECEDING_NOTE_LABEL}\\s*)(?=\\s*#{APPENDIX_SECTION_ID})"
  TITLE_APPENDIX_CITATION_LOOKAHEAD = "\\s*\\d+\\s*(?:(?:#{PART_APPENDIX_LABEL}\\s*)(?:U\\.?S\\.?C|\\d)|U\\.?S\\.?C)"
  REORGANIZATION_PLAN_CITATION_LOOKAHEAD = "\\s*\\d{4}\\s+(?:Reorganization|Reorgan\\.?|Reorg\\.?)\\s+Plan\\b"
  APPENDIX = /(?<appendix_label>,?\s*(?:appendix|table)\s*)(?<section>#{APPENDIX_ID})/ixo
  APPENDIX_EXPLICT = /(?<appendix_label>,?\s*(?:appendix|table)\s*)(?<appendix>#{APPENDIX_ID})/ixo
  APPENDIX_EXPLICT_MID = /
    (?<appendix_label_middle>,?\s*(?:appendix|table)\s*)
    (?<appendix>\d?#{APPENDIX_ID})
    (?<appendix_suffix>\s*to\s*)?
    /ixo

  APPENDIX_EXPLICT_MID_EXPANDED = /
    (?<appendix_label_middle>,?\s*(?:appendix|table|supplement\s+no\.?)\s*)
    (?<appendix>\d?(?:#{APPENDIX_ID}|\d+))
    (?<appendix_suffix>\s*to\s*)?
    /ixo

  APPENDIX_FIRST_JOIN = /
    (?:
      (?:,\s*)?appendix |
      table |
      ;\s+and\s+appendices
    )
    \s*
    /ixo

  APPENDIX_ADDITIONAL_JOIN = /
    \s*
    (?:
      and |
      appendix |
      table |
      ;\s+and\s+appendices
    )
    \s*
    /ixo

  APPENDICES = /
    (?<appendices>
      #{APPENDIX_FIRST_JOIN}
      #{APPENDIX_ID}
      (?:
        #{APPENDIX_ADDITIONAL_JOIN}
        #{APPENDIX_ID}
      )*
    )
    /ixo

  # generally ignore title structure
  replace(/
    (?<ignorable><)(?:SECTION|APPENDIX|div)[^>]*>
    /ix,
    pattern_slug: :ignorable, prepend_pattern: true)

  # reference replacements
  replace(/
      #{TITLE_SOURCE}
      #{SUBTITLE_LABEL}#{SUBTITLE}
    /ixo, pattern_slug: :labeled_subtitle, will_consider_pre_match: true)

  replace(/
      #{TITLE_SOURCE}
      (?:#{APPENDIX_EXPLICT_MID})?
      (?:#{PART_LABEL})?#{PART}
      #{SUBPART_LABEL}#{SUBPARTS}
      (?:
        (?<section_label>((?:;\s+and\s+)?(?:,\sespecially\s)?§+|sec\.?(tion)?)\s*)
        #{SECTIONS}
      )?
      (?:#{APPENDICES})?
    /ixo, pattern_slug: :labeled_part, will_consider_pre_match: true)

  replace(/
      #{TITLE_SOURCE}
      #{SUBPART_LABEL}#{SUBPARTS}
      (?:#{APPENDIX})?
    /ixo, pattern_slug: :labeled_subpart, will_consider_pre_match: true)

  replace(/
      #{TITLE_SOURCE}
      #{CHAPTER_LABEL}#{CHAPTER}
      (?:#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
      (#{APPENDIX})?
    /ixo, pattern_slug: :labeled_chapter, will_consider_pre_match: true)

  replace(/
      #{TITLE_SOURCE}
      (?<part_label>(?:parts?|pts?\.?)\s*)?
      (?<part>\d+\s*:\s*)?
      (?<section_label>(§+|sec\.?(tion)?)\s*)?
      #{SECTIONS}
      #{PARAGRAPH}
      (?:#{APPENDIX_EXPLICT})?
      #{TRAILING_BOUNDRY}
    /ixo, pattern_slug: :labeled_part_section, will_consider_pre_match: true, will_consider_post_match: true)

  # informal or non-standard patterns

  # 10 CFR § 71.5(a)(1)(ii & iii)
  replace(/
    #{TITLE_SOURCE}
    (?<part_label>(?:parts?|pts?\.?)\s*)?
    #{PART}
    (?<section_label>\s*:\s*(?:§+|sec\.?(tion)?)\s*)
    #{SECTIONS}
    #{TRAILING_BOUNDRY}
  /ixo, pattern_slug: :informal_a, will_consider_pre_match: true)

  # partial reference replacements (of this ...)

  replace(/
    (?<chapter_label>chapter\s*)(?<chapter>[A-Z]+)    # chapter - required
    (?<suffix>\s*of\s*this\s*title)                   # of this title
    /ix, pattern_slug: :chapter_of_this_title, if: :context_present?, context_expected: :title)

  replace(/
    #{SUBTITLE_LABEL}#{SUBTITLE}                      # subtitle - required
    (?<suffix>\s*of\s*this\s*title)                   # of this title
    /ixo, pattern_slug: :subtitle_of_this_title, if: :context_present?, context_expected: :title)

  replace(/
    (?:(?<prefixed_subpart_label>subpart\s*)(?<prefixed_subpart>[A-Z]+)
    (?<prefixed_subpart_connector>\s*of\s*))?         # subpart C of...
    (?<part_label>parts?\s*)#{PARTS}                  # part - required
    (?:
      (?<subpart_label>\s*,\s*subpart\s*)(?<subpart>[A-Z]+) # part 30, subpart A of this chapter
    )?
    (?<suffix>\s*of\s*this\s*(?:title|(?:sub)?chapter)) # of this title.chapter
    /ixo, pattern_slug: :part_of_this, if: :context_present?, context_expected: %i[title in_suffix])

  replace(/
    (?:
      (?<subpart_label>\s*subparts?\s*)#{SUBPARTS}
      |
      #{APPENDIX}
    )
    (?<suffix>\s*of\s*this\s*part)                    # of this part
    /ixo, pattern_slug: :of_this_part, if: :context_present?, context_expected: %i[title part])

  replace(/
    (?:
      (?<section>appendix\s*[A-Z])
      (?<appendix_of>\s*of\s*)
      (?:
        (?<prefixed_subpart_label>subpart\s*)
        (?<prefixed_subpart>#{SUBPART_ID})
        (?<prefixed_subpart_of>\s*of\s*)
      )?
      (?:
        (?<prefixed_part_label>part\s*)
        (?<prefixed_part>#{PART_ID})
        (?<prefixed_part_of>\s*of\s*)
      )?
    )?
    (?:
      (?<subchapter_label>subchapter\s*)#{SUBCHAPTER}
      (?<subchapter_of>\s*of\s*)
    )?
    (?:
      (?<chapter_label>chapter\s*)#{CHAPTER}
      (?<chapter_of>\s*of\s*)
    )?
    (?:
      (?<part_label>Part\s*)#{PART}
      (?<part_of>\s*of\s*)
    )?
    (?<title_label>Title\s*)(?<title>#{TITLE_ID})
    (?<title_connector>\s*(?:,|of\s*the)?)
    #{SOURCE_LABEL}
    /ixo, pattern_slug: :appendix_of_the, will_consider_pre_match: true)

  LIKELY_EXTERNAL_SECTIONS = /
    \A(and\s*section\s*#{SECTION_ID}#{OPTIONAL_PARENTHETICALS})?\s*
    (?:
      as\sreferenced\sin
      |
      of\s*
      (?:the|those|)
      (?:
          \s*EAR |
          \s*Order |
          \s*AHAM |
          \s*AHRI |
          \s*ANSI |
          \s*APSP |
          \s*ASHRAE |
          \s*ICC |
          \s*NFPA |
          \sPerformance\sSpecification\s\d |
          \s*this\sappendix |
          \s*UN\sManual\s |
        (?:
          (?:[\s,a-z]{0,128})
          (?:Act|Amendments|Code|regulations)
        )
      )
    )
    /ix

  LIKELY_UNLINKABLE = /revised.{0,18}(?<revised_year>(?:19|20)\d{2})/ix

  UNLINKABLE_PRE_MATCH = /
      (?:Appendix\s*(?:[A-Z0-9]{0,3}\s*)?to\s*(?:Subpart\s*[A-Z]+\s*of\s*)?\z) |
      from\sthis\sappendix,\sthe |
      When\sperforming |
      exceeds\sthe\sapplicable |
      Performance\sSpecification\s\d, |
      sub-\z |
      appendix\s[A-Za-z\d-]+\sto\sthis\spart,
    /ix

  UNLINKABLE_POST_MATCH = /
      -?\d+,\sEPA\sMethod\s\d
    /ix

  # loose section | §§

  replace(/
    (?<!["'§])                                       # avoid matching start of tag for section header
    (?:
      (?<prefixed_paragraph_label>paragraphs?\s*)
      #{PREFIXED_PARAGRAPHS}
      (?<prefixed_paragraph_suffix>\s*(?:of|in)\s*)
    )?
    (?<section_label>(?:§+|\bsection)\s*)#{LOOSE_SECTION_SECTIONS}
    #{PARAGRAPHS_OPTIONAL_LIST}
    (?<suffix>\s*(?:of\s*this\s*(?:title|(?:sub)?chapter|(?:sub)?part))?)
    (?:
      (?<spacer>contained\sin\s)
      #{TITLE_SOURCE}
      #{PART_LABEL}#{PART}
    )?
    #{TRAILING_BOUNDRY}
    /ixo, pattern_slug: :loose_section, if: :context_present?, will_consider_pre_match: true, will_consider_post_match: true, context_expected: %i[title in_suffix])

  # paragraphs

  # local list of paragraphs
  #   paragraph (b)(2)(iv)(<em>d</em>)(<em>4</em>),
  #   ...
  #   and <em>Examples 31</em> through <em>35</em> in paragraph (b)(5)
  #   of this section
  replace(/
    (?<paragraphs>
      (?:
        (?:#{ReferenceParser::HierarchyCaptures::LIST_EXAMPLES})?
        (?:sub)?paragraphs?\s*
        #{PARAGRAPH_UNLABELED_REQUIRED}
        (?:,\s*(?:and\s*)?)?
      )+
    )
    (?<suffix_unlinked>
          \s*of\sthis\s(?:sub)?section                        # of this section
    )
    /ixo, pattern_slug: :paragraph_list, if: :context_present?, context_expected: %i[title section])

  # expanded preable local list of paragraphs
  replace(/
    (?<paragraph_label>paragraphs?\s*)
    #{EXPANDED_PARAGRAPHS}
    (?<suffix>
      (?:#{EXAMPLES})?
    )
    (?<suffix_unlinked>
      \s*of\sthis\s(?:sub)?section                            # of this section
    )
    /ixo, pattern_slug: :preable_paragraph_list, if: :context_present?, context_expected: %i[title section])

  # local list of paragraphs w/out "paragraph" prefix (of this section anchor remains)
  replace(/
    (?<prefix_unlinked>in\s*|in\s*either\s*|under\s*)
    #{PARAGRAPHS}
    (?<suffix_unlinked>
      \s*of\sthis\ssection
    )
    /ixo, pattern_slug: :local_paragraph_list, if: :context_present?, context_expected: %i[title section])

  # "this paragraph"
  replace(/
    (?<prefix_unlinked>this\s*)
    (?<paragraph_label>paragraph\s*)
    #{PARAGRAPH}
    /ixo, pattern_slug: :this_paragraph, if: :context_present?, context_expected: %i[title section])

  # 3 CFR compilations
  replace(/
      (?<title>3)
      #{SOURCE_LABEL_ALLOW_SHORTHAND_CFR}
      (?<suffix_unlinked>
        ,?
        (?:19|20|21)\d\d
        [-–— ]+
        (?:
        \d{4}
        )?
        \s*
        comp
      )
    /ixo, pattern_slug: :presdoc_compilation, prepend_pattern: true)

  ET_SEQ_TRAILING_MODIFIER = /
    (?:,\s*)?
    (?:<em>\s*)?
    (?:,\s*)?
    et\s*seq\.?
    (?:\s*,|\s*;(?=\s*<\/em>))?
    (?:\s*<\/em>)?
  /ixo

  TRAILING_MODIFIER_UNLABELED = /
    (?:
      ,?\s*
      (?:
        #{ET_SEQ_TRAILING_MODIFIER} |
        preceding\s+notes?\b |
        \(\s*notes?\s*\) |
        n(?:otes?\b|t\.?(?![a-z]))
      )
    )
  /ixo

  TRAILING_MODIFIER = /
    (?<trailing_modifier>
      #{TRAILING_MODIFIER_UNLABELED}
    )?
  /ixo

  NOT_TITLE_APPENDIX_CITATION = "(?!#{TITLE_APPENDIX_CITATION_LOOKAHEAD})"
  NOT_STAT_PAGE_CITATION = "(?!\\s+\\d+[A-Za-z]?\\s+Stat\\.?)"

  LAX_USC_SECTION_LIST_DIVIDERS = /
    (?:
      <em>(?:[a-z]{1,5})? |
      <\/em>(?:[a-z]{1,5})? |
      ,#{NOT_TITLE_APPENDIX_CITATION} |
      ;#{NOT_TITLE_APPENDIX_CITATION}(?!#{REORGANIZATION_PLAN_CITATION_LOOKAHEAD})(?!\s*\d+\s+Stat\.?) |
      \)\s*,#{NOT_TITLE_APPENDIX_CITATION} |
      \)\s*and\b |
      (?<!\))\s*[-–—]\s*(?!\s*\() |
      \s*through\s* |
      \s+to\s+ |
      \s*(?:and|&)#{NOT_TITLE_APPENDIX_CITATION}#{NOT_STAT_PAGE_CITATION}\s*(?:chapters?\s+)? |
      \s*or#{NOT_TITLE_APPENDIX_CITATION}#{NOT_STAT_PAGE_CITATION}\s*(?:chapters?\s+)?
    )*
  /ixo

  TRAILING_MODIFIER_OPTIONAL = /(?:#{TRAILING_MODIFIER_UNLABELED})?/ixo

  LAX_USC_SECTION_LIST_ITEM = /
    (?:
      \s*#{LAX_USC_SECTION_NUMBER}#{USC_SECTION_EM_LETTER_SUFFIX}#{LAX_USC_SECTION_RANGE} |
      \s*[Cc]hapters?\s+(?>\d+) |
      \s*\(\s*\d{1,3}\s*\)(?:\s*[-–—]\s*\(\s*\d{1,3}\s*\))? |
      \s*\(\s*(?!notes?\s*\))[a-z]{1,5}\s*\)(?:\s*[-–—]\s*\(\s*(?!notes?\s*\))[a-z]{1,5}\s*\))? |
      \s*#{APPENDIX_ROMAN_SECTION} |
      \s*#{PART_APPENDIX_LABEL}\s*#{APPENDIX_SECTION_MARKERS}#{LAX_USC_SECTION_NUMBER}#{LAX_USC_SECTION_RANGE} |
      \s*#{PART_APPENDIX_LABEL}\s*#{APPENDIX_SECTION_MARKERS}#{APPENDIX_ROMAN_SECTION} |
      \s*#{PART_APPENDIX_LABEL}(?!\w)(?!\.?\s*#{APPENDIX_SECTION_MARKERS}#{APPENDIX_SECTION_ID})(?!\s+#{PRECEDING_NOTE_LABEL}) |
      \s*preceding\s+notes?\b |
      \s*notes?\b(?!\s+prec\.?)
    )
    ([a-z]{1,5}[-–—]\d+)?
    #{TRAILING_MODIFIER_OPTIONAL}
    (?:\.(?=\s+\d))?
    #{NEXT_TITLE_STOP}
  /ixo

  LAX_USC_SECTION_SKIP = /
    \s*(?>\d+)[a-z]+\d+
  /ixo

  # interrupting asides that should not end a USC section list (Pub. L. cites extracted separately)
  PUBL_ATTRIBUTION_ASIDE = /
    \s+(?:
      as\s+amended\s+by\s+(?:section\s+\d+\s+of\s+)? |
      added\s+by\s+
    )
    #{PL_LABEL}\d+[-–]\d+
    (?:
      \s+and\s+(?:section\s+\d+\s+of\s+)?#{PL_LABEL}\d+[-–]\d+ |
      ,\s*(?:and\s+)?#{PL_LABEL}\d+[-–]\d+
    )*
    (?:,\s*sec(?:tion|\.)?\s*\d+)?
    (?:,\s*\d+\s*Stat\.?\s*\d+)?
  /ixo

  # ", as amended, and 503" — bare phrase, not "as amended by Pub. L. ..."
  AS_AMENDED_ASIDE = /
    (?:,\s*|\s+)as\s+amended\b(?!\s+by\b)
  /ixo

  EXPLANATORY_PARENTHETICAL = /
    \s*\(\s*for\b[^)]*\d+\s*U\.?S\.?C[^)]*\)
  /ixo

  # "(Repealed in part as to offenses committed on or after November 1, 1987)"
  REPEALED_PARENTHETICAL = /
    \s*\(\s*Repealed\b[^)]*\)
  /ixo

  # "3401 (note and 3402)" — note applies to prior section; trailing number is another section
  NOTE_AND_SECTION_PARENTHETICAL = /
    \s*\(\s*notes?\s+and\s+#{LAX_USC_SECTION_NUMBER}\s*\)
  /ixo

  # "subchapters I and III of chapter 311" — cite the chapter, not the subchapters
  SUBCHAPTERS_OF_CHAPTER_ASIDE = /
    (?:,\s*|\s+)subchapters?\s+[IVXLCDM]+(?:\s*(?:,|and|&)\s*[IVXLCDM]+)*\s+of\s+chapter\s+(?>\d+)
  /ixo

  # "2601 Chap. 56 Section 5604" — chapter is locational; cite the following section
  CHAP_N_SECTION_ASIDE = /
    (?:,\s*|\s+)Ch(?:ap(?:ter)?|\.)?\.?\s*\d+\s+Sections?\s+(?=\d)
  /ixo

  # trailing artifacts after a section: "300j-9(i)BVG, 5851"
  TRAILING_UPPERCASE_ARTIFACT_ASIDE = /
    [A-Z]{2,}(?=\s*[,;])
  /xo

  LAX_USC_SECTIONS = /
    (?<sections>
      (?:
        #{LAX_USC_SECTION_LIST_DIVIDERS}
        (?:
          #{LAX_USC_SECTION_LIST_ITEM} |
          #{LAX_USC_SECTION_SKIP}
        ) |
        #{PUBL_ATTRIBUTION_ASIDE} |
        #{AS_AMENDED_ASIDE} |
        #{EXPLANATORY_PARENTHETICAL} |
        #{REPEALED_PARENTHETICAL} |
        #{NOTE_AND_SECTION_PARENTHETICAL} |
        #{SUBCHAPTERS_OF_CHAPTER_ASIDE} |
        #{CHAP_N_SECTION_ASIDE} |
        #{TRAILING_UPPERCASE_ARTIFACT_ASIDE}
      )+
    )
  /ixo

  PART_APPENDIX_LABEL_WITH_SECTION = /(?<part_appendix_label>\s*#{PART_APPENDIX_LABEL}\s*,?\s*#{APPENDIX_SECTION_MARKERS})(?=\s*#{APPENDIX_SECTION_ID})/ix
  TITLE_APPENDIX_LABEL = /(?<title_appendix_label>\s*App\.?\s*)/ix # USC
  TITLE_SOURCE_NON_CFR_WITH_APPENDIX = /(?:Title\s*)?(?<title>#{TITLE_ID})#{TITLE_APPENDIX_LABEL}?#{SOURCE_LABEL_NON_CFR}/ixo

  # primarly list replacements
  # relaxed / non-CFR
  # continuation after parenthetical (e.g. 1185 (pursuant to EO...), 1185 note, 1201)
  # also: Pub. L. 106-476 (114 Stat. 2101), sections 1434, 1435
  # also: 1202 (General Note 3(i)), Harmonized Tariff Schedule of the United States, 1624
  # also: 213n (Pub. L. 106-113 ...); 214, 214a, 217a
  replace(->(context, options) {
            /
            (?<continuation_prefix>
              \)\s*[,;]\s*
              (?:Harmonized\s+Tariff\s+Schedule\s+of\s+the\s+United\s+States(?:\s*\([^()]*\))?\s*,\s*)?
            )
            (?<section_label>sections?\s+)?
            #{LAX_USC_SECTIONS}
            #{TRAILING_MODIFIER}
            #{TRAILING_BOUNDRY}
            /ixo
          }, pattern_slug: :lax_usc_list_continuation, prepend_pattern: true, will_consider_pre_match: true)

  # 50 App. 462 (title appendix section, without repeating U.S.C.)
  replace(->(context, options) {
            /
            (?:Title\s*)?(?<title>#{TITLE_ID})\s*(?<title_appendix_label>#{PART_APPENDIX_LABEL}\s*)
            #{LAX_USC_SECTIONS}
            #{TRAILING_MODIFIER}
            #{TRAILING_BOUNDRY}
            /ixo
          }, pattern_slug: :lax_title_appendix_sections, prepend_pattern: true)

  # 15 U.S.C. 77f, 77g, 77h, 77j, 78c(b), 78<em>l,</em> 78m, 78n, 78o(d), 80a-8, 80a-20, 80a-24, 80a-29, 80b-3, 80b-4
  replace(->(context, options) {
            /
            #{TITLE_SOURCE_NON_CFR_WITH_APPENDIX}
            (?:(?<subtitle_label>subtitle\s*)(?<subtitle>[A-Z])\s*and\s*)?
            (?:(?<chapter_label>\s*chapter\s*)(?<chapter>#{CHAPTER_ID})\s*and\s*)?
            (?<section_label>\s*(?:§+|sections?|secs?\.?)\s*|\s*<\/em>\s*§+\s*<em>\s*)?
            (?:
              ,\s*(?<part_appendix_label>#{PART_APPENDIX_LABEL}\s*#{APPENDIX_SECTION_MARKERS})(?=\s*#{APPENDIX_SECTION_ID})
              |
              #{PART_APPENDIX_PRECEDING_NOTE_WITH_SECTION}
              |
              #{PART_APPENDIX_LABEL_WITH_SECTION}
            )?
            #{LAX_USC_SECTIONS}
            #{TRAILING_MODIFIER}
            #{TRAILING_BOUNDRY}
            /ixo
          }, pattern_slug: :lax_list_replacements, prepend_pattern: true)

  # catch "3 CFR," style in Authority sections
  replace(->(context, options) {
    /
    #{(options[:slash_shorthand_allowed] || options[:best_guess]) ? TITLE_SOURCE_ALLOW_SLASH_SHORTHAND_CFR : TITLE_SOURCE_CFR}
    (?<suffix>,)
    #{TRAILING_BOUNDRY}
    #{NEXT_TITLE_STOP}
    /ix
  }, pattern_slug: :presdoc_comma, prepend_pattern: true, will_consider_pre_match: true)

  # primarly list replacements
  # strict / CFR
  replace(->(context, options) {
    /
    (?:
      (?<prefixed_paragraph_label>paragraphs?\s*)
      #{PREFIXED_PARAGRAPHS}
      (?<prefixed_paragraph_suffix>\s*(?:of|in)\s*)
    )?
    #{(options[:slash_shorthand_allowed] || options[:best_guess]) ? TITLE_SOURCE_ALLOW_SLASH_SHORTHAND : TITLE_SOURCE}
    (?:(?<chapter_label>chapter\s*)(?<chapter>[A-Z]+\s*)(?<section_label>§?\s*))?
    #{SECTIONS}
    #{PARAGRAPHS_OPTIONAL_LIST}
    #{TRAILING_BOUNDRY}
    #{NEXT_TITLE_STOP}
    /ix
  }, pattern_slug: :list_replacements, prepend_pattern: true, will_consider_pre_match: true)

  # context specific patterns

  replace(->(context, _) {
    return unless context[:section].present? && context[:section].include?(".") && (context[:section].length > 3)
    /
    (?<!=(?:'|"|\#)|=(?:'|"|\#)p-|>|§\s|\#)           # properly labeled can be matched by non-context pattern, avoid tags
    (?<section>#{Regexp.escape(context[:section])})   # current section anchor
    (?<paragraph>
      #{PARAGRAPH}
    )
    #{TRAILING_BOUNDRY}
    #{NEXT_TITLE_STOP}
    /ix
  }, pattern_slug: :current_section, if: :context_present?, context_expected: :title)

  # best guess fallback patterns

  # appendix citation
  replace(->(context, options) {
    return unless options[:best_guess]
    /
    #{TITLE_SOURCE_ALLOW_SLASH_SHORTHAND_CFR}
    #{APPENDIX_EXPLICT_MID_EXPANDED}
    (?:#{PART_LABEL}#{PART})?
    (?:#{SUBPART_LABEL}#{SUBPARTS})?
    (?:#{APPENDIX})?
    #{TRAILING_BOUNDRY}
    /ixo
  }, pattern_slug: :appendix)

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    #{TITLE_SOURCE_ALLOW_SLASH_SHORTHAND}
    /ixo
  }, pattern_slug: :title_source)

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<title_label>Title\s*)(?<title>#{TITLE_ID})
    (?<source_label>\s*of\s*the\s*#{CFR_LABEL}\s*)
    /ixo
  }, pattern_slug: :title_label)

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<title_label>Title\s*)(?<title>\d+)             # title pattern anchor
    (?:#{CHAPTER_LABEL}#{CHAPTER})?
    (?:#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (?:#{PART_LABEL}#{PART})?
    (?:(?<section_label>\s*§\s*)#{SECTION})?
    /ixo
  }, pattern_slug: :part)

  # aliases
  replace(->(context, options) {
    return unless options[:allow_aliases]
    alias_patterns = HIERARCHY_ALIASES.map { |_hierarchy_alias, config| config[:pattern] }.join("|")
    /
      (?<hierarchy_alias>#{alias_patterns})
      (?:#{SUBPART_LABEL}#{SUBPARTS})?
      (?:(?<section_label>(\/|§|Section|Parts?)\s*)?#{SECTIONS})?
    /ixo
  }, pattern_slug: :alias)

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<title>\d+)                                     # title unlabeled
    #{CHAPTER_LABEL}#{CHAPTER}                        # chapter pattern anchor
    (?:#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (?:#{PART_LABEL}#{PART})?
    (?:(?<section_label>\s*(\/|§)\s*)#{SECTION})?     # allow slash shorthand for best guess
    /ixo
  })

  # no source / title label (guess only)
  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<![-–—.\d])
    (?<title>\d{1,2})
    #{TRAILING_BOUNDRY}
    (?<source_label>\s*)
    (?:#{PART_LABEL})?
    (?:#{SUBPART_LABEL}#{SUBPART})?
    (?:
      #{SECTION}
      #{TRAILING_BOUNDRY}
    )?
    /ixo
  })

  def context_present?(options)
    options[:context].present?
  end

  def handles_lists
    true
  end

  def self.url(...)
    new({}).url(...)
  end

  def url(citation, url_options = {})
    return unless citation
    citation_options = citation[:options] || {}
    citation = citation[:href_hierarchy] || citation[:hierarchy] || (citation&.include?(:title) ? citation : {})
    result = +""
    result << "https://www.ecfr.gov" if absolute?(url_options)
    result << url_current_compare_or_on(url_date_from_options(url_options || {}))
    result << "/title-#{citation[:title]}"
    result << url_messy_part(citation, options: citation_options)
    result
  end

  def url_date_from_options(url_options = {})
    current = url_options[:current] ? :current : nil
    on = url_options[:on]
    compare = url_options[:compare] || {}

    result = current || on

    result ||= [compare[:from] || :current, compare[:to] || :current] if compare[:from] || compare[:to]

    result || :current
  end

  def url_current_compare_or_on(date)
    case date
    when nil, :current, "current"
      "/current"
    when Array
      "/compare/#{date.map { |endpoint| endpoint.respond_to?(:to_formatted_s) ? endpoint.to_formatted_s(:iso) : endpoint }.join("/to/")}"
    else
      "/on/#{date.respond_to?(:to_formatted_s) ? date.to_formatted_s(:iso) : date}"
    end
  end

  def url_messy_part(hierarchy, options: {})
    result = part_or_section_string(hierarchy, options: options) <<
      sublocators_string(hierarchy)
    if !result.present?
      result << "/chapter-#{hierarchy[:chapter]}" if hierarchy[:chapter].present?
      result << "/subchapter-#{hierarchy[:subchapter]}" if hierarchy[:subchapter].present?
    end
    result << "/subtitle-#{hierarchy[:subtitle]}" if hierarchy[:subtitle].present? && !result.present?
    result
  end

  def clean_up_named_captures(captures, options: {})
    results = []

    puts "ReferenceParser::Cfr clean_up_named_captures captures #{captures}" if @debugging
    continuation_title = nil
    case options[:pattern_slug]
    when :appendix_of_the
      return :skip if appendix_of_the_title_only?(captures)
    when :lax_title_appendix_sections
      options[:source] = :usc
    when :lax_list_replacements
      return :skip if skip_lax_list_replacements?(captures, options)
    when :lax_usc_list_continuation
      resolved = resolve_lax_usc_list_continuation(captures, options)
      return resolved unless resolved.is_a?(String)
      continuation_title = resolved
      options[:source] = :usc
      if (continuation_prefix = captures[:continuation_prefix]).present?
        captures[:prefix_unlinked] = [captures[:prefix_unlinked], continuation_prefix, captures[:section_label]].compact.join
        captures.delete(:continuation_prefix)
        captures.delete(:section_label)
      end
    end
    source = citation_source_for(captures, options: options)

    # create captures (expected to preserve fidelity of original text for output)
    captures = ReferenceParser::HierarchyCaptures.new(options: options, debugging: @debugging).from_named_captures(captures)
    if continuation_title
      captures[:title] = continuation_title
    end
    captures.determine_repeated_capture

    previous_citation = nil
    captures.repeated&.each_with_index do |what, index|
      # everything available:  [captures preceeding repeated]  [   repeated rank   ]  [captures following repeated]
      #                   ex:                     paragraphs     (a), (b), and (c)     of this section
      #
      #           first loop:  [captures preceeding repeated]  [this loop's element]
      #                   ex:                     paragraphs            (a),
      #
      #     additional loops:                                  [this loop's element]
      #                   ex:                                           (b),
      #
      #            last loop:                                  [this loop's element]  [captures following repeated]
      #                   ex:                                         and (c)          of this section
      #

      loop_captures = captures.loop_captures_for(what)

      first_loop = !captures.processing_a_list || (index == 0)
      final_loop = index == (captures.repeated.count - 1)

      # create hierarchy (normalized citation data)
      hierarchy = loop_captures.build_hierarchy(index)

      hierarchy.take_missing_from_context(captures: captures) if options[:context_expected].present?
      next if hierarchy.appears_incomplete?(captures: captures)

      prefix, text, suffix = loop_captures.prefix_text_suffix(first_loop: first_loop, final_loop: final_loop)

      # cleanup hierarchy (link text is already assembled, original text can be safely normalized at this point)
      hierarchy.cleanup!(expected: captures.expected, captures: captures)
      hierarchy.cleanup_list_ranges_if_needed!(repeated_capture: captures.repeated_capture, processing_a_list: captures.processing_a_list, previous_citation: previous_citation)
      hierarchy.normalize_paragraph_ranges(text: text, previous_citation: previous_citation, captures: captures, processing_a_list: captures.processing_a_list)
      authority = hierarchy.cleanup_authority_if_needed!
      href_hierarchy = hierarchy.to_href_hierarchy(expected: captures.expected, captures: captures)
      hierarchy.finish!

      # build citation
      citation = {hierarchy: hierarchy.to_h,
                  href_hierarchy: href_hierarchy.to_h,
                  text: text}
      if (citation_options = prepare_citation_options(captures: captures, hierarchy: hierarchy)).present?
        citation[:options] = citation_options
      end
      citation[:prefix] = prefix if prefix.present?
      citation[:suffix] = suffix if suffix.present?

      if final_loop && (trailing_modifier = captures[:trailing_modifier]&.strip)&.present?
        citation[:trailing_modifier] = trailing_modifier
      end
      citation[:authority] = authority if authority.present?
      citation[:source] = source if source
      citation[:final_loop] = true if final_loop
      citation[:part_appendix_label] = captures[:part_appendix_label] if captures[:part_appendix_label].present?
      citation[:title_appendix_label] = captures[:title_appendix_label] if captures[:title_appendix_label].present?
      if captures.repeated[index + 1].to_s.strip.match?(/\A\([a-z]{1,5}\)/i)
        citation[:strip_attached_sublocators] = true
      end

      unless qualify_citation(citation, processing_a_list: captures.processing_a_list, final_loop: final_loop, previous_citation: previous_citation)
        if previous_citation && (final_loop || paragraph_only_continuation?(citation, previous_citation))
          if (merged = citation.values_at(*%i[prefix text suffix]).compact.join("")).present?
            if previous_citation[:source] == :usc && merged.match?(/\A\s*(?:and|or|&)\s+\([a-z]{1,5}\)/i)
              previous_citation[:text] = "#{previous_citation[:text]}#{merged}"
            else
              previous_citation[:suffix] = "#{previous_citation[:suffix]}#{merged}"
            end
          end
          if (paragraph = citation.dig(:hierarchy, :paragraph)).present?
            previous_citation[:paragraph_list_continuation] = paragraph
          end
          citation = nil
        else
          citation[:hierarchy] = nil
          citation[:href_hierarchy] = nil
        end
      end

      if (citation = resolve_aliases(citation, captures))
        previous_citation = citation
        puts Rainbow("adding citation #{citation}").blue if @debugging
        results << citation
      end
    end

    eject_text_if_needed(results)
    results.each { |result| result.delete(:paragraph_list_continuation) }
    weave_embedded_public_laws!(results, captures)
    weave_as_amended_asides!(results, captures)
    return :skip unless qualify_match(captures, results: results, options: options)
    validate_and_persist(context: options[:context], references: results) if @validation_and_persistence

    results
  end

  def weave_as_amended_asides!(results, captures)
    text = captures[:as_amended_aside_text]
    return results unless text.present?

    target = [captures[:sections_before_as_amended_aside].to_i - 1, 0].max
    return results unless results[target]

    woven = text.sub(/\A,\s*/, "")
    if (next_result = results[target + 1]) && next_result[:text].to_s.match?(/\Aand\s+/i)
      results[target][:suffix] = "#{results[target][:suffix]}#{woven}, and "
      next_result[:text] = next_result[:text].sub(/\Aand\s+/i, "")
    else
      results[target][:suffix] = "#{results[target][:suffix]} #{woven}"
    end
    results
  end

  def weave_embedded_public_laws!(results, captures)
    publs = captures[:embedded_public_laws]
    stats = captures[:embedded_stats]
    return results unless publs.present? || stats.present?

    insert_at = [captures[:sections_before_publ_aside].to_i, results.length].min
    if publs.present?
      results.insert(insert_at, *publs)
      insert_at += publs.length
    end
    results.insert(insert_at, *stats) if stats.present?
    results
  end

  def publ_asides_from_sections(sections)
    return unless sections.present?

    aside = sections.match(PUBL_ATTRIBUTION_ASIDE)
    return unless aside

    remainder = sections.sub(aside[0], "").strip
    return unless remainder.empty? || remainder.match?(/\A[,;.]+/)

    embedded = ReferenceParser::Usc.embedded_publ_citations(aside[0])
    if (stat = ReferenceParser::Stat.embedded_from_comma_aside(aside[0]))
      after_aside = sections[aside.end(0)..].to_s
      embedded += [stat] if after_aside.blank? || !after_aside.match?(/\A\s*[,;.]+/)
    end
    embedded.presence
  end

  def resolve_aliases(citation, captures)
    if captures[:alias_hierarchies].present?
      if captures[:alias_hierarchies].count > 1
        hierarchy = citation.delete(:hierarchy)
        href_hierarchy = citation.delete(:href_hierarchy)
        captures[:alias_hierarchies].each do |alias_hierarchy|
          citation[:ambiguous] ||= []
          citation[:ambiguous] << alias_hierarchy.merge(hierarchy)
          citation[:ambiguous_href] ||= []
          citation[:ambiguous_href] << alias_hierarchy.merge(href_hierarchy)
        end
      else
        citation[:hierarchy].merge!(captures[:alias_hierarchies].first)
        citation[:href_hierarchy].merge!(captures[:alias_hierarchies].first)
      end
    end
    citation
  end

  def qualify_match(captures, results: nil, options: nil)
    issue = nil

    case options[:pattern_slug]
    when :lax_usc_list_continuation
      pre_match = options[:full_pre_match] || options[:pre_match]
      scoped_pre_match = usc_list_continuation_pre_match(pre_match)
      issue = :missing_usc_context unless scoped_pre_match&.match?(USC_CITATION_CONTEXT)
    when :loose_section
      puts "qualify_match options[:post_match] #{options[:post_match]}" if @debugging
      if options[:pre_match] && /[^m]>\s*\Z/ix.match?(options[:pre_match])
        issue = :heading_title # reject anything other then <em>
      elsif (match = LIKELY_EXTERNAL_SECTIONS.match(options[:post_match]))
        issue = :direct_match
      elsif !captures[:section_label]&.include?("§") && (
            a_closer_than_b_in_haystack("<td", "</table>", options[:pre_match], reference: :end) ||
            a_closer_than_b_in_haystack("</td", "<table>", options[:post_match], reference: :start))
        issue = :loose_section_table_column # 40/52.1570 "state citations"
      end
      if !issue || (issue == :heading_title)
        potential_danger = captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)
        puts "potential_danger #{potential_danger}" if @debugging

        # previously identified as unrelated
        if potential_danger.detect { |section| @accumulated_context[:sections].include?(section) }
          issue = :context_match
        else
          prefixes = potential_danger.filter_map { |s| s.include?(".") ? s.split(".")[0] : nil }
          if prefixes.detect { |prefix| @accumulated_context[:section_prefixes].include?(prefix) }
            issue = :context_prefix_match
          end
        end

        # fails to match common formatting
        if potential_danger.present?
          if !potential_danger.detect { |r| r.include?(".") }
            issue = :formatting
          elsif options[:context][:appendix].present?
            issue = :formatting unless captures[:section_label]&.include?("§") || /of this part/i.match?(captures[:suffix])
          end
        end
      end
      if issue && (issue != :heading_title) && (issue != :loose_section_table_column)
        sections = captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)
        @accumulated_context[:sections].merge(sections)
        @accumulated_context[:section_prefixes].merge(sections.filter_map { |s| s.include?(".") ? s.split(".")[0] : nil })

        puts "qualify_match @accumulated_context #{@accumulated_context}" if @debugging
      end

      unless issue
        match = LIKELY_UNLINKABLE.match(options[:post_match])
        if match
          revised_year = match[:revised_year].to_i
          if revised_year > 0 && revised_year < 2017
            issue = :likely_unlinkable_date
          end
        end
      end
    when :of_this_part
      issue = :misconstrued_plural if results.detect { it[:hierarchy][:subpart] && /s/i.match?(it[:hierarchy][:subpart]) && /subparts/i.match?(it[:text]) }
    end

    if !options[:source] || (options[:source] == :cfr)
      issue ||= :pre_match_unlinkable if options[:pre_match].present? && (UNLINKABLE_PRE_MATCH =~ options[:pre_match])
      if @debugging && (issue == :pre_match_unlinkable)
        puts Rainbow("qualify_match pre_match_unlinkable [").blue + Rainbow(options[:pre_match].to_s).green + Rainbow("]").blue
        puts Rainbow("qualify_match pre_match_unlinkable [").red + Rainbow(UNLINKABLE_PRE_MATCH.match(options[:pre_match]).to_s).orange + Rainbow("]").red
      end
      issue ||= :post_match_unlinkable if options[:post_match].present? && (UNLINKABLE_POST_MATCH =~ options[:post_match])
      if @debugging && (issue == :post_match_unlinkable)
        puts Rainbow("qualify_match post_match_unlinkable [").blue + Rainbow(options[:post_match].to_s).green + Rainbow("]").blue
        puts Rainbow("qualify_match post_match_unlinkable [").red + Rainbow(UNLINKABLE_POST_MATCH.match(options[:post_match]).to_s).orange + Rainbow("]").red
      end
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_CFR_TITLE)
    elsif options[:source] == :federal_register
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_FR_TITLE)
    end

    issue = :failure_to_preserve_source_characters if !issue && captures[:embedded_public_laws].blank? && captures[:as_amended_aside_text].blank? && !preserved_character_count?(captures, results: results)
    issue ||= :unlikely_link_start if results&.any? { |result| unlikely_link_start?(result[:text]) }

    puts Rainbow("qualify_match #{issue}").red if @debugging && issue
    !issue
  end

  def preserved_character_count?(captures, results: nil)
    result_characters = results.sum do |result|
      result.values_at(:prefix, :text, :suffix).compact.sum(&:length)
    end
    if @debugging
      text = results.map { |result| result.values_at(:prefix, :text, :suffix).compact.join }.join
      puts "preserved_character_count? #{result_characters} vs #{captures.captured_characters} \"#{text}\""
    end
    result_characters == captures.captured_characters
  end

  def qualify_citation(citation, processing_a_list: nil, final_loop: nil, previous_citation: nil)
    issue = nil
    if final_loop && processing_a_list
      issue = :unlikely_trailing_identifier if ReferenceParser::Guesses.unlikely_trailing_identifier?(citation[:text])
    end
    if paragraph_only_usc_shorthand?(citation, processing_a_list: processing_a_list, previous_citation: previous_citation)
      issue = :paragraph_only_shorthand
    end
    puts "qualify_citation #{issue}" if @debugging && issue
    !issue
  end

  def paragraph_only_usc_shorthand?(citation, processing_a_list: nil, previous_citation: nil)
    return false unless processing_a_list && citation[:source] == :usc

    paragraph = citation.dig(:hierarchy, :paragraph).to_s
    return false unless paragraph.match?(LONE_PARAGRAPH)

    stripped_text = citation[:text].to_s.strip.sub(/[;,]\s*\z/, "")
    return true if stripped_text.empty?
    return true if stripped_text.match?(/\Athrough\s+\([a-z]{1,5}\)\z/i)

    prev_paragraph = previous_citation&.[](:paragraph_list_continuation).presence ||
      previous_citation&.dig(:hierarchy, :paragraph).to_s
    consecutive = consecutive_lettered_paragraphs?(prev_paragraph, paragraph)

    if stripped_text.match?(LONE_PARAGRAPH)
      return consecutive if citation.dig(:hierarchy, :section).present?

      return citation[:prefix].to_s !~ /\b(and|or|&)\s*\z/i &&
          citation[:text].to_s !~ /\A\s*(?:and|or|&)\b/i
    end

    if stripped_text.match?(/\A(?:and|or|&)\s+\([a-z]{1,5}\)\z/i)
      return false unless previous_citation
      return false if previous_citation[:text].to_s.match?(/\d+\([a-z]{1,5}\)\s*\z/i)
      return consecutive
    end

    false
  end

  def paragraph_only_continuation?(citation, previous_citation)
    paragraph_only_usc_shorthand?(citation, processing_a_list: true, previous_citation: previous_citation)
  end

  def consecutive_lettered_paragraphs?(previous_paragraph, paragraph)
    prev = previous_paragraph.to_s.match(/\A\(([a-z]{1,5})\)\z/i)&.[](1)&.downcase
    curr = paragraph.to_s.match(/\A\(([a-z]{1,5})\)\z/i)&.[](1)&.downcase
    return false unless prev && curr && prev.length == 1 && curr.length == 1

    curr.ord == prev.ord + 1
  end

  def enforce_title_range(title, min: nil, max: nil)
    if title.present?
      title_value = title.to_i
      :invalid_title if (min && (title_value < min)) || (max && (title_value > max))
    end
  end

  def citation_source_for(captures = {}, options: nil)
    source = nil
    if captures[:source_label]&.present?
      if USC_LABEL.match?(captures[:source_label]) || IRC_LABEL.match?(captures[:source_label])
        source = :usc
      elsif (FR_LABEL =~ captures[:source_label]) && !(CFR_LABEL =~ captures[:source_label])
        source = :federal_register
      end
    end
    source ||= options[:source] if options&.[](:source)
    options[:source] = source if source && options
    source
  end

  def validate_and_persist(context: nil, references: nil)
    references = references.select { |r| !r[:source] || (r[:source] == :cfr) }
    return unless references.present?
    @validation_and_persistence&.persist(context: context, references: references)
  end

  def normalize_options(options)
    context = prepare_context(options)
    options[:context] = context if context.present?
  end

  def prepare_context(options)
    result = options&.[](:context) || {}
    if (composite_hierarchy = options&.[](:composite_hierarchy) || result[:composite_hierarchy])
      result.reverse_merge!(ReferenceParser::Hierarchy.hash_from_composite(composite_hierarchy))
    end
    result || {}
  end

  def prepare_citation_options(captures: nil, hierarchy: nil)
    results = {}
    if [captures&.options&.[](:context_expected)].flatten&.include?(:in_suffix) && (captures[:suffix].include?("subpart") || captures[:suffix].include?("part"))
      results[:explicitly_expected] = [:part]
    end
    results
  end

  # url related

  def title_for(hierarchy)
    return "#{hierarchy[:title]} CFR Subtitle #{hierarchy[:subtitle]}" if hierarchy[:subtitle].present?
    return "#{hierarchy[:title]} CFR Chapter #{hierarchy[:chapter]}" if hierarchy[:chapter].present?
    "#{hierarchy[:title]} CFR"
  end

  def part_or_section_string(hierarchy, options: {})
    result = +""
    content = hierarchy[:appendix] || hierarchy[:section]

    part = subpart = section = appendix = nil

    if !hierarchy[:part] && (section = hierarchy[:section])
      # no-op
    elsif !content && ((subject_group = hierarchy[:subject_group]) || (subpart = hierarchy[:subpart]))
      part = hierarchy[:part]
    elsif !hierarchy[:section] && (appendix = hierarchy[:appendix])
      part = hierarchy[:part]
      subpart = hierarchy[:subpart]
    elsif (part = hierarchy[:part])
      if (section = hierarchy[:section])
        part = nil unless hierarchy[:part].present? && options&.[](:explicitly_expected)&.include?(:part)
      end
    end

    result << "/part-#{part}" if part
    result << "/subpart-#{subpart}" if subpart && !appendix
    result << "/subject-group-#{subject_group}" if subject_group && !appendix
    result << "/section-#{ReferenceParser::Cfr.section_string(hierarchy)}" if section
    result << "/appendix-#{appendix}" if appendix
    result
  end

  def self.section_string(hierarchy)
    if hierarchy[:part] && hierarchy[:section]&.start_with?(hierarchy[:part] + ".")
      hierarchy[:section].to_s
    elsif hierarchy[:appendix]
      hierarchy[:appendix]
    else
      hierarchy.values_at(*%i[part section]).select(&:present?).join(".")
    end
  end

  def sublocators_string(hierarchy)
    return "" unless hierarchy[:sublocators]
    +"#p-" << ReferenceParser::Cfr.section_string(hierarchy).gsub("%20", "-") << hierarchy[:sublocators]
  end

  def redundant_usc_note_match?(match_text, pre_match:)
    return false unless lax_list_replacements_regexp

    pattern_match = match_text.match(lax_list_replacements_regexp)
    return false unless pattern_match&.begin(0)&.zero?
    return false unless pattern_match[:title].present? && USC_LABEL.match?(pattern_match[:source_label].to_s)

    redundant_usc_notes?(pre_match, pattern_match[:sections])
  end

  private

  def lax_list_replacements_regexp
    return @lax_list_replacements_regexp if defined?(@lax_list_replacements_regexp)
    @lax_list_replacements_regexp = replacements.find { |r| r.pattern_slug == :lax_list_replacements }&.regexp
  end

  def appendix_of_the_title_only?(captures)
    structural = captures.values_at(:section, :part, :chapter, :subchapter, :appendix, :prefixed_part, :prefixed_subpart)
    captures[:title_connector]&.strip == "," && captures[:title].present? && structural.none?(&:present?)
  end

  def skip_lax_list_replacements?(captures, options)
    if captures[:source_label].present? &&
        !(USC_LABEL.match?(captures[:source_label]) || IRC_LABEL.match?(captures[:source_label]) || FR_LABEL.match?(captures[:source_label]))
      return true
    end
    return true if !captures[:title].present? && captures[:sections].present? && options[:pre_match]&.match?(USC_CITATION_CONTEXT)

    redundant_usc_notes?(options[:full_pre_match] || options[:pre_match], captures[:sections])
  end

  # returns the title (String) to continue the preceding USC list under,
  # standalone aside citations (Array), or :skip
  def resolve_lax_usc_list_continuation(captures, options)
    sections = captures[:sections].to_s
    return :skip if sections.match?(AS_AMENDED_ASIDE) && !sections.match?(/\d/)

    pre_match = options[:full_pre_match] || options[:pre_match]
    scoped_pre_match = usc_list_continuation_pre_match(pre_match)
    continuation_title = scoped_pre_match.scan(/(\d+)\s+U\.?S\.?C(?!\.?A\b)/i).last&.first if scoped_pre_match&.match?(USC_CITATION_CONTEXT)
    return publ_asides_from_sections(captures[:sections]) || :skip unless continuation_title

    # "), sections 1434" after a Stat. cite — not Exchange Act "), sections 15B..."
    return :skip if captures[:section_label].present? && !pre_match.match?(/\b\d+\s+Stat\.?\s*\d+\s*\z/i)
    return :skip if skip_lax_usc_list_continuation?(pre_match)

    continuation_title
  end

  def usc_list_continuation_pre_match(pre_match)
    return unless pre_match.present?

    pre_match.split(LIST_CONTINUATION_BLOCK_BOUNDARY).last.presence || pre_match
  end

  def skip_lax_usc_list_continuation?(pre_match)
    return true unless pre_match.present?
    return true if pre_match.match?(/\([A-Z][A-Z0-9.-]{1,5}\z/)

    return false if pre_match.rstrip.end_with?(")")
    return false if inside_usc_parenthetical?(pre_match)

    pre_match.match?(/\d+\((?:[a-z]{1,5}|\d+)\s*\z/i) ||
      pre_match.match?(/\d+\([a-z]{1,5}\)-\([a-z]{1,5}\s*\z/i) ||
      pre_match.match?(/\([a-z]{1,5}\)\([^)]*\z/i)
  end

  def inside_usc_parenthetical?(pre_match)
    last_begin = nil
    pre_match.scan(/\(\s*\d+\s+U\.?S\.?C(?!\.?A\b)/i) { last_begin = Regexp.last_match.begin(0) }
    return false unless last_begin

    depth = 0
    pre_match[last_begin..].each_char do |char|
      depth += 1 if char == "("
      depth -= 1 if char == ")"
      return false if depth == 0
    end

    depth > 0
  end

  def redundant_usc_notes?(pre_match, sections)
    return false unless pre_match.present? && sections.present?

    items = sections.split(/,|\band\b/i).map(&:strip).reject(&:empty?)
    return false unless items.all? { |item| item.match?(/\bnotes?\b/i) }

    items.all? do |item|
      base = item.sub(/\s+notes?\b.*\z/i, "").strip
      pre_match.match?(/\b#{Regexp.escape(base)}\s+notes?\b/i)
    end
  end

  def a_closer_than_b_in_haystack(a, b, haystack, reference: :start)
    return unless haystack

    if reference == :end
      if (a_index = haystack.rindex(a))
        b_index = haystack.rindex(b)
        true if !b_index || (b_index < a_index)
      end
    elsif (a_index = haystack.index(a))
      b_index = haystack.index(b)
      true if !b_index || (b_index > a_index)
    end
  end

  EJECTABLE_SUFFIX = /
      \s*of\sthis\schapter\s*
      \z
    /ixo

  def eject_text_if_needed(results)
    return unless results.count > 1
    if (match = EJECTABLE_SUFFIX.match((last = results[-1])[:text]))
      last[:text] = last[:text].delete_suffix(match[0])
      last[:suffix] = match[0] + (last[:suffix] || "")
    end
  end
end
