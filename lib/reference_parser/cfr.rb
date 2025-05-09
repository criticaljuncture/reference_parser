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
  IRC_LABEL = /I(?:nternal)?\.?\s*R(?:evenue)?\.?\s*C(?:ode)?\.?/ix
  FR_LABEL = /F(?:ederal)?\.?\s*R(?:egister)?\.?/ix

  SOURCE_LABEL = /(?<source_label>\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL})\s*)/ixo
  SOURCE_LABEL_CFR = /(?<source_label>\s*#{CFR_LABEL}\s*)/ixo
  SOURCE_LABEL_NON_CFR = /(?<source_label>\s*(?:#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL})\s*)/ixo

  SOURCE_LABEL_ALLOW_SHORTHAND = /(?<source_label>\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL}|\/)\s*)/ixo
  SOURCE_LABEL_ALLOW_SHORTHAND_CFR = /(?<source_label>\s*(?:#{CFR_LABEL}|\/)\s*)/ixo
  SOURCE_LABEL_ALLOW_SHORTHAND_NON_CFR = /(?<source_label>\s*(?:#{USC_LABEL}|#{FR_LABEL}|#{IRC_LABEL}|\/)\s*)/ixo

  TITLE_SOURCE = /(?<title>#{TITLE_ID})#{SOURCE_LABEL}/ixo
  TITLE_SOURCE_CFR = /(?<title>#{TITLE_ID})#{SOURCE_LABEL_CFR}/ixo
  TITLE_SOURCE_NON_CFR = /(?<title>#{TITLE_ID})#{SOURCE_LABEL_NON_CFR}/ixo # laxer section list requirements

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
    (?!\d|\s*(?:
        C\.?F\.?R| # CFR
        U\.?S\.?C| # USC
        F\.?R\.?|  # FR
        I\.?R\.?C| # IRC
        Comp\.|
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
    to\b |
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

  PARAGRAPH = /(?<paragraph>#{PARAGRAPH_UNLABELED})/ixo
  PARAGRAPH_REQUIRED = /(?<paragraph>#{PARAGRAPH_UNLABELED_REQUIRED})/ixo

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

  # empty connection option intentional for paragraphs directly following section
  PARAGRAPHS_OPTIONAL = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELED_REQUIRED}|\d+\.\d+)
      )*
    )
    /ixo

  PARAGRAPHS_OPTIONAL_LIST = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|;|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELED_REQUIRED}|\d+\.\d+)
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

  LOOSE_SECTION_SECTIONS = /
    (?<sections>
      (?:
        (?:#{LOOSE_SECTION_JOIN_SECTION})?
        #{SECTION_UNLABELED}
      )+
    )
    /ixo

  APPENDIX_ID = /[A-Z]+/ixo
  APPENDIX = /(?<appendix_label>,?\s*(?:appendix|table)\s*)(?<section>#{APPENDIX_ID})/ixo
  APPENDIX_UNLABELED = /,?\s*(?:appendix|table)\s*#{APPENDIX_ID}/ixo
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
    /ixo, pattern_slug: :labeled_part_section, will_consider_pre_match: true)

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
    \A\s*
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
          \s*this\sappendix |
        (?:
          (?:[\s,a-z]{0,128})
          (?:Act|Amendments|Code|regulations)
        )
      )
    )
    /ix

  LIKELY_UNLINKABLE = /revised.{0,18}(?<revised_year>(?:19|20)\d{2})/ix

  UNLINKABLE_PRE_MATCH = /
      (?:Appendix\s*to\s*)|(?:Appendix\s*[A-Z0-9]{0,3}\s*to\s*\z) |
      from\sthis\sappendix,\sthe |
      When\sperforming |
      exceeds\sthe\sapplicable
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

  # primarly list replacements
  # relaxed / non-CFR
  # 15 U.S.C. 77f, 77g, 77h, 77j, 78c(b), 78<em>l,</em> 78m, 78n, 78o(d), 80a-8, 80a-20, 80a-24, 80a-29, 80b-3, 80b-4
  replace(->(context, options) {
            /
            #{TITLE_SOURCE_NON_CFR}
            (?<section_label>\s*§\s*|\s*<\/em>\s*§\s*<em>\s*)?
            (?<sections>
              (?:
                (?: <em>(?:[a-z]{1,5})?|<\/em>(?:[a-z]{1,5})?|,|[-–—]|\s*through\s*|\s*and\s*|\s*or\s*)*
                (?:
                  \s*\d+(?:[a-z]{1,5})? |
                  \(\s*\d+\s*\) |
                  \(\s*[a-z]{1,5}\s*\)
                )
                ([a-z]{1,5}[-–—]\d+)?
                (?:\s*note)?
                #{NEXT_TITLE_STOP}
              )+
            )
            #{TRAILING_BOUNDRY}
            /ixo
          }, pattern_slug: :lax_list_replacements, prepend_pattern: true)

  # catch "3 CFR," style in Authority sections
  replace(->(context, options) {
    /
    #{(options[:slash_shorthand_allowed] || options[:best_guess]) ? TITLE_SOURCE_ALLOW_SLASH_SHORTHAND : TITLE_SOURCE}
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
    source = citation_source_for(captures, options: options)

    # create captures (expected to preserve fidelity of original text for output)
    captures = ReferenceParser::HierarchyCaptures.new(options: options, debugging: @debugging).from_named_captures(captures)
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
      hierarchy.cleanup_list_ranges_if_needed!(repeated_capture: captures.repeated_capture, processing_a_list: captures.processing_a_list)
      hierarchy.normalize_paragraph_ranges(text: text, previous_citation: previous_citation, captures: captures, processing_a_list: captures.processing_a_list)
      href_hierarchy = hierarchy.to_href_hierarchy(expected: captures.expected, captures: captures)
      hierarchy.finish!

      # build citation
      citation = {hierarchy: hierarchy.to_h,
                  href_hierarchy: href_hierarchy.to_h,
                  prefix: prefix,
                  text: text,
                  suffix: suffix,
                  options: prepare_citation_options(captures: captures, hierarchy: hierarchy)}

      citation[:source] = source if source

      unless qualify_citation(citation, processing_a_list: captures.processing_a_list, final_loop: final_loop)
        if final_loop && previous_citation
          previous_citation[:suffix] += citation.values_at(*%i[prefix text suffix]).join("")
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

    return :skip unless qualify_match(captures, results: results, options: options)
    validate_and_persist(context: options[:context], references: results) if @validation_and_persistence

    results
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

    if options[:pattern_slug] == :loose_section
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
    end

    if !options[:source] || (options[:source] == :cfr)
      issue ||= :pre_match_unlinkable if options[:pre_match].present? && (UNLINKABLE_PRE_MATCH =~ options[:pre_match])
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_CFR_TITLE)
    elsif options[:source] == :federal_register
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_FR_TITLE)
    end

    issue = :failure_to_preserve_source_characters if !issue && !preserved_character_count?(captures, results: results)

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

  def qualify_citation(citation, processing_a_list: nil, final_loop: nil)
    issue = nil
    if final_loop && processing_a_list
      issue = :unlikely_trailing_identifier if ReferenceParser::Guesses.unlikely_trailing_identifier?(citation[:text])
    end
    puts "qualify_citation #{issue}" if @debugging && issue
    !issue
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

  private

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
end
