class ReferenceParser::Cfr < ReferenceParser::Base
  MAX_EXPECTED_CFR_TITLE = 50
  MAX_EXPECTED_FR_TITLE = 999

  def link_options(citation)
    {class: "cfr external"}
  end

  # sub-patterns & utilities

  TITLE_ID = /\d+/
  SUBTITLE_ID = /(?:[A-Z]{1,7})/ix
  CHAPTER_ID = /[IVXLCDM0-9]+/ix
  SUBCHAPTER_ID = /[A-Z]+[-_]?[A-Z]*/ix
  PART_ID = /\w+[\-–—]?\w*/ix
  SUBPART_ID = /\w{1,4}[\w.\-–—]{0,6}(?:suspended)?/ix # constraint /\w+[\w.\-–—]*\w*/ix generated/internal ECFR[0-9A-Z]{15,16}
  SUBPART_ID_ADDITIONAL = /\w{1,4}([.\-–—][\w.\-–—]{0,5}|)(?:suspended)?\b/ix
  SECTION_ID = /[\w\-]+.?[\w\-–—()]*/ix

  CFR_LABEL = /C\.?\s*F\.?\s*R\.?/ix
  USC_LABEL = /U(?:nited)?\.?\s*S(?:tates)?\.?\s*C(?:ode)?\.?/ix
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
    (?!\s*(?:
        C\.?F\.?R| # CFR
        U\.?S\.?C| # USC
        F\.?R\.?|  # FR
        I\.?R\.?C| # IRC
        Comp\.|
        ,?\s*subpart|
        \/         # dates
    ))/ix

  TRAILING_BOUNDRY = /(?!\.?\d|\/)/ix # don't stop mid-number or date

  JOIN = /\s*(?!CFR)(?:,|(?:,\s*|)and\b|(?:,\s*|)or\b|through)\s*/ixo
  JOIN_SECTION = /\s*(?!CFR)(?:,|(?:,\s*|)and\b|(?:,\s*|)or\b|to\b|through)\s*/ixo

  CHAPTER_LABEL = /(?<chapter_label>\s*Ch(?:ap(?:ter)?)?\s*)/ix
  CHAPTER = /(?<chapter>#{CHAPTER_ID})/ixo
  SUBCHAPTER_LABEL = /(?<subchapter_label>\s*Subch(?:ap(?:ter)?)?\s*)/ix
  SUBCHAPTER = /(?<subchapter>#{SUBCHAPTER_ID})/ixo

  SUBPART_LABEL = /(?<subpart_label>,?\s*subparts?\s*)/ix
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
        (?:\s|,|and|or|through|-|(?:\s*part\s*))+
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

  PARAGRAPH_UNLABELLED = /\s*#{PARENTHETICALS}*(-\d+)?/ixo
  PARAGRAPH_UNLABELLED_REQUIRED = /\s*#{PARENTHETICALS}+(-\d+)?/ixo

  PARAGRAPH = /(?<paragraph>#{PARAGRAPH_UNLABELLED})/ixo
  PARAGRAPH_REQUIRED = /(?<paragraph>#{PARAGRAPH_UNLABELLED_REQUIRED})/ixo

  PARAGRAPHS = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        #{PARAGRAPH_UNLABELLED_REQUIRED}
        (?:
          (?:\s|,|and|or|through)+
          #{PARAGRAPH_UNLABELLED_REQUIRED}
        )*
      )
    )
    /ixo

  PREFIXED_PARAGRAPHS = /
  (?<prefixed_paragraphs>                          # list of paragraphs
    (?:
      (?:\s*and\s*)?
      #{PARAGRAPH_UNLABELLED_REQUIRED}
    )*
  )
  /ixo

  # empty connection option intentional for paragraphs directly following section
  PARAGRAPHS_OPTIONAL = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELLED_REQUIRED}|\d+\.\d+)
      )*
    )
    /ixo

  PARAGRAPHS_OPTIONAL_LIST = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELLED_REQUIRED}|\d+\.\d+)
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

  SECTION_UNLABELLED = /
    \d+#{NEXT_TITLE_STOP}(?:\.\d+)?#{NEXT_TITLE_STOP}(?:[a-z]{1,3}\d?)?
    #{OPTIONAL_PARENTHETICALS}
    (?:
      [a-z]\d+-\d |
      -\d+T?[a-z]? | # dash suffix if present tends to mark end of section area
      \.\d+  |
      \(T\)    # temporary may be marked w T suffix
    )*

    \s*#{NEXT_TITLE_STOP}
    /ixo

  SECTION = /(?<section>#{SECTION_UNLABELLED})/ixo

  SECTIONS = /
    (?<sections>
      (?:
        (?:#{JOIN_SECTION})?
        #{SECTION_UNLABELLED}                         # additional sections
      )+
    )
    /ixo

  APPENDIX = /(?<section>(?<appendix_label>,?\s*appendix\s*)[A-Z]+)/ixo

  # reference replacements

  replace(/
      #{TITLE_SOURCE}                                   # title
      (?<part_label>part\s*)?(?<part>\d+)                # labelled part
      #{SUBPART_LABEL}#{SUBPARTS}
      (?:#{APPENDIX})?
    /ixo)

  replace(/
      #{TITLE_SOURCE}                                   # title
      (?<chapter_label>chapter\s*)                      # labelled chapter
      (?<chapter>[A-Z]+\s*)
    /ixo)

  replace(/
      #{TITLE_SOURCE}
      (?<part_label>parts?\s*)?
      (?<section_label>(§+|sec\.?(tion)?)\s*)?
      #{SECTIONS}
      #{PARAGRAPH}
      #{TRAILING_BOUNDRY}
    /ixo)

  # partial reference replacements (of this ...)

  replace(/
    (?<chapter_label>chapter\s*)(?<chapter>[A-Z]+)    # chapter - required
    (?<suffix>\s*of\s*this\s*title)                   # of this title
    /ix, if: :context_present?, context_expected: :title)

  replace(/
    (?<subtitle_label>subtitle\s*)(?<subtitle>[A-Z])  # subtitle - required
    (?<suffix>\s*of\s*this\s*title)                   # of this title
    /ix, if: :context_present?, context_expected: :title)

  replace(/
    (?:(?<prefixed_subpart_label>subpart\s*)(?<prefixed_subpart>[A-Z]+)
    (?<prefixed_subpart_connector>\s*of\s*))?         # subpart C of...
    (?<part_label>parts?\s*)#{PARTS}                  # part - required
    (?:
      (?<subpart_label>\s*,\s*subpart\s*)(?<subpart>[A-Z]+) # part 30, subpart A of this chapter
    )?
    (?<suffix>\s*of\s*this\s*(?:title|(?:sub)?chapter)) # of this title.chapter
    /ixo, if: :context_present?, context_expected: %i[title in_suffix])

  replace(/
    (?:
      (?<subpart_label>\s*subparts?\s*)#{SUBPARTS}
      |
      #{APPENDIX}
    )
    (?<suffix>\s*of\s*this\s*part)                    # of this part
    /ixo, if: :context_present?, context_expected: %i[title part])

  LIKELY_EXTERNAL_SECTIONS = /
      of\s*
      (?:the|those)
      (?:
          \s*EAR |
          \s*Order |
        (?:
          (?:[\s,a-z]{0,128})
          (?:Act|Amendments|Code|regulations)
        )
      )
    /ix

  # loose section

  replace(/
    (?<![>"'§])                                       # avoid matching start of tag for section header
    (?:
      (?<prefixed_paragraph_label>paragraphs?\s*)
      #{PREFIXED_PARAGRAPHS}
      (?<prefixed_paragraph_suffix>\s*(?:of|in)\s*)
    )?
    (?<section_label>(§+|section)\s*)#{SECTIONS}
    #{PARAGRAPHS_OPTIONAL_LIST}
    (?<suffix>\s*(of\s*this\s*(title|chapter))?)
    #{TRAILING_BOUNDRY}
    /ixo, pattern_slug: :loose_section, if: :context_present?, will_consider_post_match: true, context_expected: %i[title in_suffix])

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
        paragraph\s*
        #{PARAGRAPH_UNLABELLED}
        (?:,\s*(?:and\s*)?)?
      )+
    )
    (?<suffix_unlinked>
          \s*of\sthis\ssection                        # of this section
    )
    /ixo, if: :context_present?, context_expected: %i[title section])

  # expanded preable local list of paragraphs
  replace(/
    (?<paragraph_label>paragraphs?\s*)
    #{EXPANDED_PARAGRAPHS}
    (?<suffix>
      (?:#{EXAMPLES})?
    )
    (?<suffix_unlinked>
      \s*of\sthis\ssection                            # of this section
    )
    /ixo, if: :context_present?, context_expected: %i[title section])

  # local list of paragraphs w/out "paragraph" prefix (of this section anchor remains)
  replace(/
    (?<prefix_unlinked>in\s*|in\s*either\s*|under\s*)
    #{PARAGRAPHS}
    (?<suffix_unlinked>
      \s*of\sthis\ssection
    )
    /ixo, if: :context_present?, context_expected: %i[title section])

  # "this paragraph"
  replace(/
    (?<prefix_unlinked>this\s*)
    (?<paragraph_label>paragraph\s*)
    #{PARAGRAPH}
    /ixo, if: :context_present?, context_expected: %i[title section])

  # primarly list replacements
  # relaxed / non-CFR
  # 15 U.S.C. 77f, 77g, 77h, 77j, 78c(b), 78<em>l,</em> 78m, 78n, 78o(d), 80a-8, 80a-20, 80a-24, 80a-29, 80b-3, 80b-4
  replace(->(context, options) {
            /
            #{TITLE_SOURCE_NON_CFR}
            (?<section_label>\s*§\s*)?
            (?<sections>
              (?:
                (?: <em>(?:[a-z]{1,5})?|<\/em>(?:[a-z]{1,5})?|,|-|\s*through\s*|\s*and\s*|\s*or\s*)*
                (?:
                  \s*\d+(?:[a-z]{1,5})? |
                  \(\s*\d+\s*\) |
                  \(\s*[a-z]{1,5}\s*\) |
                )
                ([a-z]{1,5}-\d+)?
                #{NEXT_TITLE_STOP}
              )+
            )
            #{TRAILING_BOUNDRY}
            /ixo
          }, prepend_pattern: true)

  # primarly list replacements
  # strict / CFR
  replace(->(context, options) {
    /
    (?:
      (?<prefixed_paragraph_label>paragraphs?\s*)
      #{PREFIXED_PARAGRAPHS}
      (?<prefixed_paragraph_suffix>\s*(?:of|in)\s*)
    )?
    #{options[:slash_shorthand_allowed] || options[:best_guess] ? TITLE_SOURCE_ALLOW_SLASH_SHORTHAND : TITLE_SOURCE}
    (?:(?<chapter_label>chapter\s*)(?<chapter>[A-Z]+\s*)(?<section_label>§?\s*))?
    #{SECTIONS}
    #{PARAGRAPHS_OPTIONAL_LIST}
    #{TRAILING_BOUNDRY}
    #{NEXT_TITLE_STOP}
    /ix
  }, prepend_pattern: true)

  # context specific patterns

  replace(->(context, _) {
    return unless context[:section].present? && context[:section].include?(".") && (context[:section].length > 3)
    /
    (?<!=(?:'|"|\#)|=(?:'|"|\#)p-|>|§\s|\#)           # properly labelled can be matched by non-context pattern, avoid tags
    (?<section>#{Regexp.escape(context[:section])})   # current section anchor
    (?<paragraph>
      #{PARAGRAPH}
    )
    /ix
  }, if: :context_present?, context_expected: :title)

  # best guess fallback patterns

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    #{TITLE_SOURCE_ALLOW_SLASH_SHORTHAND}
    /ixo
  }, prepend_pattern: true)

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<title_label>Title\s*)(?<title>\d+)             # title pattern anchor
    (?:#{CHAPTER_LABEL}#{CHAPTER})?
    (?:#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (?:#{PART_LABEL}#{PART})?
    (?:(?<section_label>\s*§\s*)#{SECTION})?
    /ixo
  })

  replace(->(context, options) {
    return unless options[:best_guess]
    /
    (?<title>\d+)                                     # title unlabelled
    #{CHAPTER_LABEL}#{CHAPTER}                        # chapter pattern anchor
    (?:#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (?:#{PART_LABEL}#{PART})?
    (?:(?<section_label>\s*(\/|§)\s*)#{SECTION})?     # allow slash shorthand for best guess
    /ixo
  })

  def context_present?(options)
    options[:context].present?
  end

  def url(citation, url_options = {})
    return unless citation
    citation = citation[:href_hierarchy] || citation[:hierarchy] || (citation&.include?(:title) ? citation : {})
    result = ""
    result << "https://ecfr.federalregister.gov" if absolute?(url_options)
    result << url_current_compare_or_on(url_date_from_options(url_options || {}))
    result << "/title-#{citation[:title]}"
    result << url_messy_part(citation)
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

  def url_messy_part(hierarchy)
    result = part_or_section_string(hierarchy) <<
      sublocators_string(hierarchy)
    result << "/subtitle-#{hierarchy[:subtitle]}" if hierarchy[:subtitle].present? && !result.present?
    result << "/chapter-#{hierarchy[:chapter]}" if hierarchy[:chapter].present? && !result.present?
    result
  end

  EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS = %i[
    prefix
    prefixed_subpart_label prefixed_subpart prefixed_subpart_connector
    prefixed_paragraph_label prefixed_paragraph prefixed_paragraph_suffix
    title_label title source_label
    subtitle_label subtitle
    chapter_label chapter
    subchapter_label subchapter
    part_label part
    subpart_label subpart
    section_label section none
    paragraph_label paragraph paragraph_range_end
    suffix
  ]
  # also: prefix_unlinked / suffix_unlinked

  def clean_up_named_captures(captures, options: {})
    results = []

    puts "ReferenceParser::Cfr clean_up_named_captures captures #{captures}" if @debugging
    source = citation_source_for(captures)

    # create captures (expected to preserve fidelity of original text for output)
    captures = ReferenceParser::HierarchyCaptures.new(options: options, debugging: @debugging).from_named_captures(captures)
    captures.determine_repeated_capture

    # partition the available capture groups into a prefix set and suffix set based
    # on the position of the repeated capture (if any)
    index = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS.find_index(captures.repeated_capture)
    first_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[0..index]
    last_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[index..]

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

      # create hierarchy (normalized citation data)
      hierarchy = loop_captures.build_hierarchy
      hierarchy.take_missing_from_context(captures: captures) if options[:context_expected].present?
      next if hierarchy.appears_incomplete?(captures: captures)

      # reassemble capture text for link
      text_from_captures = !captures.processing_a_list || (index == 0) ? first_loop_named_captures : [] # first loop/prefix
      text_from_captures << captures.repeated_capture
      text_from_captures.concat(last_loop_named_captures) if index == (captures.repeated.count - 1) # last loop/suffix

      final_loop = index == (captures.repeated.count - 1)
      loop_prefix_unlinked = index == 0 ? captures[:prefix_unlinked] || "" : ""
      loop_prefix = index == 0 ? captures[:prefix] || "" : ""
      loop_suffix = final_loop ? captures[:suffix] || "" : ""
      loop_suffix_unlinked = final_loop ? captures[:suffix_unlinked] || "" : ""

      text = (loop_prefix || "") + loop_captures.slice(*text_from_captures).values.join + (loop_suffix || "")

      # cleanup hierarchy (link text is already assembled, original text can be safely normalized at this point)
      hierarchy.cleanup!(expected: captures.expected)
      hierarchy.cleanup_list_ranges_if_needed!(repeated_capture: captures.repeated_capture, processing_a_list: captures.processing_a_list)
      hierarchy.normalize_paragraph_ranges(text: text, previous_citation: previous_citation, captures: captures, processing_a_list: captures.processing_a_list)
      href_hierarchy = hierarchy.to_href_hierarchy(expected: captures.expected)
      hierarchy.finish!

      # build citation
      citation = {hierarchy: hierarchy.to_h,
                  href_hierarchy: href_hierarchy.to_h,
                  prefix: loop_prefix_unlinked,
                  text: text,
                  suffix: loop_suffix_unlinked}

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

      if citation
        previous_citation = citation
        puts "adding citation #{citation}" if @debugging
        results << citation
      end
    end

    return :skip unless qualify_match(captures, results: results)
    validate_and_persist(context: options[:context], references: results) if @validation_and_persistence

    results
  end

  def qualify_match(captures, results: nil)
    issue = nil
    # return false if /\A\s*\[Reserved\]/ix =~ captures[:post_match]
    if captures[:pattern_slug] == :loose_section
      puts "qualify_match captures[:post_match] #{captures[:post_match]}" if @debugging
      match = LIKELY_EXTERNAL_SECTIONS.match(captures[:post_match])
      if match
        issue = :direct_match
      end
      unless issue
        potential_danger = captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)

        # previously identified as unrelated
        if (@accumulated_context & potential_danger).present?
          issue = :context_match
        end

        # fails to match common formatting
        if potential_danger.present? && !potential_danger.detect { |r| r.include?(".") }
          issue = :formating
        end
      end
      if issue
        @accumulated_context.concat(captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)).uniq!
        puts "qualify_match @accumulated_context #{@accumulated_context}" if @debugging
      end
    end

    if !captures[:source] || (captures[:source] == :cfr)
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_CFR_TITLE)
    elsif captures[:source] == :federal_register
      issue ||= enforce_title_range(captures[:title], min: 1, max: MAX_EXPECTED_FR_TITLE)
    end

    puts "qualify_match #{issue}" if @debugging && issue
    !issue
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

  def citation_source_for(captures = {})
    source = nil
    if captures[:source_label]&.present?
      if USC_LABEL.match?(captures[:source_label]) || IRC_LABEL.match?(captures[:source_label])
        source = :usc
      elsif (FR_LABEL =~ captures[:source_label]) && !(CFR_LABEL =~ captures[:source_label])
        source = :federal_register
      end
    end
    captures[:source] = source if source
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
      hierarchy_from_composite = %i[title subtitle chapter subchapter part subpart section_identifier]
        .zip(composite_hierarchy.split(":")).to_h

      hierarchy_from_composite.delete_if { |k, v| v.blank? }
      hierarchy_from_composite[:section] = hierarchy_from_composite[:section_identifier] if hierarchy_from_composite[:section_identifier]

      result.reverse_merge!(hierarchy_from_composite)
    end
    result || {}
  end

  # url related

  def title_for(hierarchy)
    return "#{hierarchy[:title]} CFR Subtitle #{hierarchy[:subtitle]}" if hierarchy[:subtitle].present?
    return "#{hierarchy[:title]} CFR Chapter #{hierarchy[:chapter]}" if hierarchy[:chapter].present?
    "#{hierarchy[:title]} CFR"
  end

  def part_or_section_string(hierarchy)
    return "/section-#{hierarchy[:section]}" if hierarchy[:section] && !hierarchy[:part]
    return "" unless hierarchy[:part]
    return "/part-#{hierarchy[:part]}/subpart-#{hierarchy[:subpart]}" if !hierarchy[:section] && hierarchy[:subpart]
    return "/part-#{hierarchy[:part]}/appendix-#{hierarchy[:appendix]}" if !hierarchy[:section] && hierarchy[:appendix]
    return "/part-#{hierarchy[:part]}" unless hierarchy[:section]
    "/section-#{hierarchy[:part]}.#{hierarchy[:section]}"
  end

  def sublocators_string(hierarchy)
    return "" unless hierarchy[:sublocators]
    result = "#p-#{hierarchy[:part]}"
    result << "." if hierarchy[:part] && hierarchy[:section]
    result << (hierarchy[:section]).to_s if hierarchy[:section]
    result << (hierarchy[:sublocators]).to_s
  end
end
