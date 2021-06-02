class ReferenceParser::Cfr < ReferenceParser::Base
  def link_options(citation)
    {class: "cfr external"}
  end

  # sub-patterns & utilities

  TITLE_ID = /\d+/
  SUBTITLE_ID = /(?:[A-Z]{1,7})/ix
  CHAPTER_ID = /[IVXLCDM0-9]+/ix
  SUBCHAPTER_ID = /[A-Z]+[-_]?[A-Z]*/ix
  PART_ID = /\w+[\-–—]?\w*/ix
  SUBPART_ID = /\w+[\w.\-–—]*\w*/ix
  SECTION_ID = /[\w\-]+.?[\w\-–—()]*/ix

  CFR_LABEL = /C\.?\s*F\.?\s*R\.?/ix
  USC_LABEL = /U(?:nited)?\.?\s*S(?:tates)?\.?\s*C(?:ode)?\.?/ix
  FR_LABEL = /F(?:ederal)?\.?\s*R(?:egister)?\.?/ix
  SOURCE_LABEL = /(?<source_label>\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL})\s*)/ixo
  SOURCE_LABEL_ALLOW_SHORTHAND = /(?<source_label>\s*(?:#{CFR_LABEL}|#{USC_LABEL}|#{FR_LABEL}|\/)\s*)/ixo

  TITLE_SOURCE = /
    (?<title>#{TITLE_ID})
    #{SOURCE_LABEL}
    /ixo

  TITLE_SOURCE_ALLOW_SLASH_SHORTHAND = /
    (?<title>#{TITLE_ID})
    #{SOURCE_LABEL_ALLOW_SHORTHAND}
    /ixo

  # "1 CFR 11 and 2 CFR 22" vs "1 CFR 11 and 12" needed after
  # simple digits patterns that could match the next title
  NEXT_TITLE_STOP = /
    (?!\s*(?:
        C\.?F\.?R|
        U\.?S\.?C|
        F\.?R\.?
    ))/ix

  TRAILING_BOUNDRY = /(?!\.?\d)/ix # don't stop mid-number

  CHAPTER_LABEL = /(?<chapter_label>\s*Ch(?:ap(?:ter)?)?\s*)/ix
  CHAPTER = /(?<chapter>#{CHAPTER_ID})/ixo
  SUBCHAPTER_LABEL = /(?<subchapter_label>\s*Subch(?:ap(?:ter)?)?\s*)/ix
  SUBCHAPTER = /(?<subchapter>#{SUBCHAPTER_ID})/ixo
  SUBPART_LABEL = /(?<subpart_label>,?\s*subparts?\s*)/ix
  SUBPART = /(?<subpart>#{SUBPART_ID})/ixo
  PART_LABEL = /(?<part_label>\s*Part\s*)/ix
  PART = /(?<part>#{PART_ID})/ixo

  PARENTHETICALS = /
    (?: \((?:<em>)?[a-z]{1,3}(?:<\/em>)?\)\s* | # (a)(b)...
        \((?:<em>)?\d{1,3}(?:<\/em>)?\)\s*  | # (1)(2)...
        \((?:<em>)?[xvi]{1,7}(?:<\/em>)?\)\s*   # (i)(iv)...
    )
    /ix

  OPTIONAL_PARENTHETICALS = /#{PARENTHETICALS}*/ixo

  PARAGRAPH_UNLABELLED = /\s*#{PARENTHETICALS}*(-\d+)?/ixo
  PARAGRAPH_UNLABELLED_REQUIRED = /\s*#{PARENTHETICALS}+(-\d+)?/ixo

  PARAGRAPH = /(?<paragraph>#{PARAGRAPH_UNLABELLED})/ixo
  PARAGRAPH_REQUIRED = /(?<paragraph>#{PARAGRAPH_UNLABELLED_REQUIRED})/ixo

  LIST_DESIGNATORS = /,|or|and|through/ix

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

  # empty connection option intentional for paragraphs directly following section
  PARAGRAPHS_OPTIONAL = /
    (?<paragraphs>                          # list of paragraphs
      (?:
        (?:\s|,|and|or|through||-)+
        (?:#{PARAGRAPH_UNLABELLED_REQUIRED}|\d+\.\d+)
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

  PARAGRAPH_EXAMPLE_PREFIX = /
    (<em>)?\s*Examples?\s*.                           # required example text
    (?:
      (?:<em>)?\s*(?:Examples?\s*)?                   # optional italics and or repeated example test
      \d+                                             # number
      (?:<\/em>)?                                     # close italics if needed
      (?:\s*through\s*|\s*,\s*(?:and\s*)?)?
    )+                                                # allow a list of examples
    (?:\s*in\s*)?                                     # in
    /ix

  SECTION_UNLABELLED = /
    \d+#{NEXT_TITLE_STOP}(\.\d+)?#{NEXT_TITLE_STOP}([a-z]\d?)?
    #{OPTIONAL_PARENTHETICALS}
    (?:
      [a-z]\d+-\d |
      -\d+T? | # dash suffix if present tends to mark end of section area
      \.\d+  |
      \(T\)    # temporary may be marked w T suffix
    )*
    \s*#{NEXT_TITLE_STOP}
    /ixo

  SECTION = /(?<section>#{SECTION_UNLABELLED})/ixo

  SECTIONS = /
    (?<sections>
      #{SECTION_UNLABELLED}
      (
        \s*(?!CFR)(,|(,\s*|)and|(,\s*|)or|through)\s* # join
        #{SECTION_UNLABELLED}                         # additional sections
      )*
    )
    /ixo

  SUBPARTS = /
    (?<subparts>
      #{SUBPART_ID}
      (
        \s*(?!CFR)(,|(,\s*|)and|(,\s*|)or|through)\s*   # join
        #{SUBPART_ID}                                   # additional sections
      )*
    )
    /ixo

  # reference replacements

  replace(/
      #{TITLE_SOURCE}                                   # title
      (?<part_label>part\s*)(?<part>\d+)                # labelled part
      #{SUBPART_LABEL}#{SUBPARTS}
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
    (?<part_label>part\s*)(?<part>\d+)                # part - required
    (?:
      (?<subpart_label>\s*,\s*subpart\s*)(?<subpart>[A-Z]+) # part 30, subpart A of this chapter
    )?
    (?<suffix>\s*of\s*this\s*(?:title|chapter))         # of this title.chapter
    /ix, if: :context_present?, context_expected: %i[title in_suffix])

  replace(/
    (?:
      (?<subpart_label>\s*subpart\s*)(?<subpart>[A-Z]+) # subpart
      |
      (?<section>(?<appendix_label>\s*appendix\s*)[A-Z]+) # appendix
    )
    (?<suffix>\s*of\s*this\s*part)                    # of this part
    /ix, if: :context_present?, context_expected: %i[title part])

  LIKELY_EXTERNAL_SECTIONS = /
    of\s*
    (?:the|those)
    (?:[\s,a-z]{0,128})
    (?:Act|Amendments|Code|regulations)
    /ix

  # loose section
  replace(/
    (?<![>"'§])                                       # avoid matching start of tag for section header
    (?:
      (?<prefixed_paragraph_label>paragraph\s*)
      (?<prefixed_paragraph>#{PARAGRAPH_UNLABELLED})
      (?<prefixed_paragraph_suffix>\s*of\s*)
    )?
    (?<section_label>(§+|section)\s*)#{SECTIONS}
    #{PARAGRAPHS_OPTIONAL}
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
        (?:#{PARAGRAPH_EXAMPLE_PREFIX})?
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

  replace(->(context, options) {
    /
    (?:
      (?<prefixed_paragraph_label>paragraph\s*)
      (?<prefixed_paragraph>#{PARAGRAPH_UNLABELLED})
      (?<prefixed_paragraph_suffix>\s*of\s*)
    )?
    #{options[:slash_shorthand_allowed] || options[:best_guess] ? TITLE_SOURCE_ALLOW_SLASH_SHORTHAND : TITLE_SOURCE}
    #{SECTIONS}
    (?<paragraphs>#{PARAGRAPH_UNLABELLED}
      (?:\s*and\s*#{PARAGRAPH_UNLABELLED})?
    )
    #{TRAILING_BOUNDRY}
    /ix
  }, prepend_pattern: true)

  # context specific patterns

  replace(->(context, _) {
    return unless context[:section].present? && context[:section].include?(".") && (context[:section].length > 3)
    /
    (?<!=(?:'|")|=(?:'|")p-|§\s)                          # properly labelled can be matched by non-context pattern, avoid tags
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
    context = options[:context] || {}
    context_expected = [options&.[](:context_expected)].flatten
    captures = prepare_captures(captures)

    expected = { # determine expected captures
      subtitle: captures[:subtitle_label].present?,
      subchapter: captures[:subchapter_label].present?,
      part: captures.values_at(*%i[part_label appendix_label]).detect(&:present?),
      subpart: captures.values_at(*%i[prefixed_subpart_label subpart_label]).detect(&:present?),
      section: captures[:section_label].present?
    }

    # determine repeated capture (if any)
    repeated, repeated_capture = determine_repeated_capture(captures)
    processing_a_list = (repeated.count > 1) || captures[:part_label]&.include?("parts")

    # partition the available capture groups into a prefix set and suffix set based
    # on the position of the repeated capture (if any)
    index = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS.find_index(repeated_capture)
    first_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[0..index]
    last_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[index..]

    previous_citation = nil
    repeated&.each_with_index do |what, index|
      loop_captures = {repeated_capture => what}.reverse_merge(captures.except(:prefix, :suffix))
      prepare_loop_captures(loop_captures, processing_a_list: processing_a_list)

      # build hierarchy
      hierarchy_elements = %i[title chapter]
      hierarchy_elements << :subchapter if expected[:subchapter]
      hierarchy_elements.concat(%i[section part])
      hierarchy_elements << :subtitle if expected[:subtitle]
      hierarchy_elements.concat(%i[subpart prefixed_subpart]) if expected[:subpart]
      hierarchy_elements << :part if expected[:part]
      hierarchy_elements.concat(%i[paragraph prefixed_paragraph])
      hierarchy = loop_captures.slice(*hierarchy_elements)

      # fill in hierarchy from context (if needed)
      if options[:context_expected].present?
        available_from_context = determine_available_from_context(hierarchy, context: context, context_expected: context_expected, captures: captures)
        available_from_context.each do |k|
          hierarchy[k] = context[k] if context[k].present? && !hierarchy[k].present?
        end
      end
      next if hierarchy_appears_incomplete?(hierarchy, context_expected: context_expected || {}, captures: captures)

      # reassemble text for link
      text_from_captures = !processing_a_list || (index == 0) ? first_loop_named_captures : [] # first loop/prefix
      text_from_captures << repeated_capture
      text_from_captures.concat(last_loop_named_captures) if index == (repeated.count - 1) # last loop/suffix

      loop_prefix_unlinked = index == 0 ? captures[:prefix_unlinked] || "" : ""
      loop_prefix = index == 0 ? captures[:prefix] || "" : ""
      loop_suffix = index == (repeated.count - 1) ? captures[:suffix] || "" : ""
      loop_suffix_unlinked = index == (repeated.count - 1) ? captures[:suffix_unlinked] || "" : ""

      text = (loop_prefix || "") + loop_captures.slice(*text_from_captures).values.join + (loop_suffix || "")

      # cleanup hierarchy
      hierarchy = cleanup_hierarchy(hierarchy, expected: expected)
      hierarchy = cleanup_hierarchy_for_list_ranges_if_needed(hierarchy, repeated_capture: repeated_capture, processing_a_list: processing_a_list)
      normalize_paragraph_ranges(hierarchy, text: text, previous_citation: previous_citation, captures: captures) if previous_citation
      href_hierarchy = cleanup_hierarchy_for_href(hierarchy, expected: expected)

      # build citation
      citation = {hierarchy: hierarchy,
                  href_hierarchy: href_hierarchy,
                  prefix: loop_prefix_unlinked,
                  text: text,
                  suffix: loop_suffix_unlinked}

      previous_citation = citation
      qualify_result_sources(citation, captures: captures)
      puts "adding citation #{citation}" if @debugging

      results << citation
    end

    return :skip unless qualify_match(captures, results: results)

    results
  end

  def hierarchy_ranks
    %i[subtitle chapter subchapter part subpart section paragraph]
  end

  def hierarchy_appears_incomplete?(hierarchy, context_expected: [], captures: {})
    result = hierarchy_ranks.detect do |rank|
      context_expected.include?(rank) &&
        !hierarchy[rank].present?
    end

    if context_expected.include?(:in_suffix)
      hierarchy_ranks.each do |rank|
        if captures[:suffix]&.downcase&.include?(rank.to_s)
          result ||= !hierarchy[rank].present? && (!%i[chapter].include?(rank) || !hierarchy[:section].present?)
          break if result
        end
      end
    end

    result ||= !hierarchy[:title].present?
    puts "hierarchy_appears_incomplete? #{result} #{hierarchy}" if @debugging && result
    result
  end

  def determine_repeated_capture(captures)
    repeated_capture, repeated = nil, nil

    to_consider = %i[section subpart paragraph].map { |rank| ["#{rank}s".to_sym, rank] }

    to_consider.each_with_index do |rank_keys, index|
      rank_values = captures.values_at(*rank_keys).flatten.select(&:present?)
      if !repeated || (!repeated.present? && rank_values.present?) ||
          (
            repeated.is_a?(Array) && ((repeated.count == 1) &&
            rank_values.is_a?(Array) && ((rank_values&.count || 0) >= 2))
          )
        repeated = rank_values
        repeated_capture = rank_keys.last
      end
    end

    repeated_capture, repeated = :none, [""] unless repeated.present?
    slide_left(captures, :paragraph, :paragraphs) if repeated != :paragraph

    [repeated, repeated_capture]
  end

  def split_lists_into_individual_items(captures, keys, simple: false)
    keys.each do |key|
      original = captures[key]
      next unless original.present?
      clean = captures[key].dup

      specific_all_dividers = nil
      specific_all_dividers = /(?<split>(,|\s+|and|or|through|#{PARAGRAPH_EXAMPLE_PREFIX})+)/ixo if key == :paragraphs

      if simple
        # look-behind includes match in split (instead of discarding)
        clean[key] = clean[key]&.split(/(?<=(?:,|through|or|and))/)
      else
        # split on any list markers, then absorb into values prefering
        # commas to the left and connectors to the right
        any_divider = /(?<split>(?:\s*(?:,|and|or|through)\s*))/ix
        all_dividers = specific_all_dividers || /(?<split>(?:,|\s+|and|or|through)+)/ix
        trailing_dividers = /and|or|through/ix
        if (split = clean&.split(any_divider)&.select { |s| s.length > 0 })
          x = 1
          while x < split.length
            # puts "split x #{x} split #{split}" if @debugging
            if /\A#{all_dividers}\z/i.match?(split[x]) # only list cruft              
              if (split[x] =~ trailing_dividers) && (x < (split.length - 1))
                split[x + 1] = split[x] + split[x + 1]
              else
                split[x - 1] = split[x - 1] + split[x]
              end
              split.delete_at(x)
            else
              x += 1
            end
          end
          captures[key] = split if split.count > 1
        end
      end
      if @debugging
        puts "split_lists_into_individual_items \"#{original}\" into \"#{captures[key]}\"" if @debugging && original != captures[key]
      end
    end
  end

  def qualify_match(captures, results: nil)
    result = true
    # return false if /\A\s*\[Reserved\]/ix =~ captures[:post_match]
    if captures[:pattern_slug] == :loose_section && !captures[:section_label].include?("§")

      puts "qualify_match captures[:post_match] #{captures[:post_match]}" if @debugging
      match = LIKELY_EXTERNAL_SECTIONS.match(captures[:post_match])

      if match
        result = false
      end
      if result
        potential_danger = captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)

        # previously identified as unrelated
        result = false if (@accumulated_context & potential_danger).present?

        # fails to match common formatting
        result = false unless potential_danger.detect { |r| r.include?(".") }

        @accumulated_context.concat(potential_danger).uniq!

      end
      unless result
        @accumulated_context.concat(captures.values_at(:section, :sections).flatten.compact.map(&:strip).select(&:present?)).uniq!
      end
    end
    puts "qualify_match #{result}" if @debugging && !result
    result
  end

  def qualify_result_sources(citation, captures: {})
    if captures[:source_label]&.present?
      citation[:source] = :usc if USC_LABEL.match?(captures[:source_label])
      citation[:source] = :federal_register if (FR_LABEL =~ captures[:source_label]) && !(CFR_LABEL =~ captures[:source_label])
    end
    captures[:source_label]
  end

  def determine_available_from_context(hierarchy, context: {}, context_expected: [], captures: {})
    results = []

    results << :title if context[:title] && !hierarchy[:title].present? &&
      context_expected.include?(:title)

    results << :section if context[:section] && !hierarchy[:section].present? &&
      (hierarchy[:paragraph].present? || hierarchy[:subpart].present?) &&
      (context_expected.include?(:section) ||
      context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("section"))

    if context[:chapter] && !hierarchy[:chapter].present? &&
        (hierarchy[:paragraph].present? || hierarchy[:subpart].present? || hierarchy[:part].present?) &&
        !hierarchy[:section].present? && !results.include?(:section) &&
        (!context_expected.include?(:section) ||
        context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("chapter"))
      results << :chapter
    end

    results << :part if context[:part] && !hierarchy[:part].present? &&
      (
        hierarchy[:paragraph].present? ||
        hierarchy[:subpart].present? ||
        (hierarchy[:section].present? && !hierarchy[:section]&.include?("."))
      ) &&
      (context_expected.include?(:part) ||
      context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("part"))

    puts "determine_available_from_context \"#{results}\" context_expected \"#{context_expected}\"" if @debugging
    results
  end

  def prepare_captures(captures)
    captures = captures.select { |k, v| v }.symbolize_keys

    slide_right(captures, :paragraph, :suffix) if only_whitespace?(captures[:paragraph])

    slide_right(captures, :sections, :section) if captures[:sections] && !captures[:section] && !(LIST_DESIGNATORS =~ captures[:sections])

    restore_paragraph(captures)
    
    if list?(captures[:sections]) && list?(captures[:paragraphs])
      captures[:rolled_up_paragraphs] = true
      slide_left(captures, :sections, :paragraphs)
    end

    split_lists_into_individual_items(captures, %i[subparts sections paragraphs])
    slide_left(captures, :section, :part_string)

    captures
  end

  def list?(capture)
    LIST_DESIGNATORS =~ capture
  end

  def prepare_loop_captures(captures, processing_a_list: false)
    restore_paragraph(captures) unless processing_a_list
  end

  def restore_paragraph(captures)
    # sections aren't expected to have parentheticals w/out a dashed suffix
    if captures[:section]&.include?("(") && !captures[:section]&.include?("-")
      paragraph_key = captures[:paragraphs].present? ? :paragraphs : :paragraph
      repartition(captures, :section, "(", paragraph_key)
    end
  end

  def normalize_sections(sections)
    last_section = nil
    sections.each do |section|      
      puts "section #{section} last_section #{last_section}"
      last_section = section
    end    
  end

  def normalize_paragraph_ranges(hierarchy, text: nil, previous_citation: nil, captures: {})
    return unless previous_citation    
    previous_hierarchy = previous_citation[:hierarchy]
    if ((hierarchy[:paragraph]&.count("(") || 0) == 0) &&
        (hierarchy[:paragraph]&.include?(".") || numbers_seem_like_a_range?([hierarchy[:paragraph], hierarchy[:section]].compact))
      # this seems like the list has jumped back up to sections
      hierarchy[:section] = hierarchy[:paragraph]
      hierarchy.delete(:paragraph)
      puts "normalize_paragraph_ranges reverting paragraph to section #{hierarchy[:section]} <= #{hierarchy[:paragraph]}" if @debugging
    end

    if ((hierarchy[:paragraph]&.count("(") || 0) == 1) &&
        ((previous_hierarchy[:paragraph]&.count("(") || 0) > 1) &&
        ((/and|or|through/ =~ text) || (/and|or|through/ =~ captures[:paragraph]))
      potential_prefix = previous_hierarchy[:paragraph].rpartition("(").first
      potential_update = potential_prefix + hierarchy[:paragraph]
      if guess_paragraph_level(hierarchy[:paragraph]) != guess_paragraph_level(potential_prefix.rpartition("(").last)
        puts "normalize_paragraph_ranges #{potential_update} <= #{hierarchy[:paragraph]}" if @debugging
        hierarchy[:paragraph] = potential_update
      elsif @debugging
        puts "normalize_paragraph_ranges ignored same levels #{potential_update} <=/= #{hierarchy[:paragraph]}"
      end
    end

    # paragraphs rolled up into sections
    if captures[:rolled_up_paragraphs] && hierarchy[:section]&.start_with?("(") && !hierarchy[:paragraph] && previous_citation.dig(:hierarchy, :section)&.include?("(")
      slide_right(hierarchy, :section, :paragraph)
      hierarchy[:section] = previous_citation.dig(:hierarchy, :section).partition("(").first
    end
  end

  def guess_paragraph_level(fragment)
    clean_fragment = fragment.tr("(", "").tr(")", "")
    clean_fragment&.to_i != 0 ? :numbers : :letters # pending ParagraphHierarchy::Level?
  end

  def repartition(captures, left, pivot, right, drop_divider: false)
    left_value, pivot_value, right_value = captures.values_at(left, right).compact.join.partition(pivot)
    right_value = [pivot_value, right_value].compact.join unless drop_divider
    if left_value.length > 0
      captures[left] = left_value
    else
      captures.delete(left)
    end
    if right_value.length > 0
      captures[right] = right_value
    else
      captures.delete(right)
    end
  end

  def normalize_options(options)
    context = prepare_context(options)
    options[:context] = context if context.present?
  end

  def prepare_context(options)
    result = options&.[](:context) || {}
    if (composite_hierarchy = options&.[](:composite_hierarchy) || result[:composite_hierarchy])
      hierarchy_from_composite = %i[title subtitle chapter subchapter part subpart section_identifier]
        .zip(composite_hierarchy
                                 .split(":")).to_h

      hierarchy_from_composite.delete_if { |k, v| v.blank? }
      hierarchy_from_composite[:section] = hierarchy_from_composite[:section_identifier] if hierarchy_from_composite[:section_identifier]

      result.reverse_merge!(hierarchy_from_composite)
    end
    result || {}
  end

  def cleanup_hierarchy(hierarchy, expected: {})
    result = hierarchy

    # drop any list or range related items that made it through
    if result[:paragraph].present?
      result[:paragraph].gsub!(PARAGRAPH_EXAMPLE_PREFIX, "") if result[:paragraph].include?("xample")
    end
    result.transform_values! do |value|
      list_items = /(\s+|,|or|and|through)+/i
      value.gsub(/\A#{list_items}/, "") # prefixed whitespace / list items
        .gsub(/#{list_items}\z/, "") # suffixed whitespace / list items
    end

    # hierarchy shouldn't contain unknowns
    result.reject! { |k, v| v.blank? }

    decide_section_vs_part(result, expected: expected)

    slide_right(result, :prefixed_subpart, :subpart)
    slide_right(result, :prefixed_paragraph, :paragraph)

    if result[:paragraph].present?
      result[:paragraph].gsub!(/paragraph\s*/, "")
      result[:paragraph] = result[:paragraph].partition("through").first.strip if result[:paragraph].include?("through")
    end

    result
  end

  def decide_section_vs_part(hierarchy, expected: {})
    if !hierarchy[:part] && hierarchy[:section]
      if @options[:prefer_part] && !hierarchy[:section]&.include?(".")
        repartition(hierarchy, :part, ".", :section, drop_divider: true)
      elsif expected[:part]
        # take section if missing part & expecting it
        slide_left(hierarchy, :part, :section)
      end
    end
  end

  def cleanup_hierarchy_for_list_ranges_if_needed(hierarchy, repeated_capture: :section, processing_a_list: nil)
    effective_capture = repeated_capture
    effective_capture = :part if effective_capture == :section && !hierarchy[effective_capture]
    if %i[section part paragraph].include?(effective_capture) && hierarchy[effective_capture]&.include?("-") && !hierarchy[effective_capture]&.include?(".")
      items = hierarchy[effective_capture].split("-")
      if (effective_capture == :paragraph) || numbers_seem_like_a_range?(items.map(&:to_i))
        puts "cleanup_hierarchy_for_list_ranges_if_needed AAA \"#{items.first}\"-\"#{items.last}\" <= \"#{hierarchy[effective_capture]}\"" if @debugging
        hierarchy[effective_capture] = items.first.to_s
        hierarchy["#{effective_capture}_end".to_sym] = items.last.to_s
      end
    end
    hierarchy
  end

  def cleanup_hierarchy_for_href(hierarchy, expected: {})
    result = hierarchy.dup

    if (result[:section] && !result[:part]) || (result[:part] && !result[:section])
      part_section = result.values_at(:section, :part).join
      if part_section.include?(".")
        result[:part], _, result[:section] = part_section.partition(".")
      else
        unless expected[:section]
          result[:part] = part_section
          result.delete(:section)
          puts "cleanup_hierarchy_for_href deleting section" if @debugging
        end
      end
    end

    result[:paragraph].gsub!(/\s*\(last\s*sentence\)\s*/ix, "") if result[:paragraph].present?

    drop_whitespace_and_italics(result, :paragraph)

    # from match 12 CFR § 275.206(a)(3)-3 expecting "/on/2021-05-17/title-12/section-275.206(a)(3)-3"
    slide_left(result, :section, :paragraph) if result[:paragraph]&.include?("-")

    slide_right(result, :paragraph, :sublocators) # url uses "sublocators"

    puts "cleanup_hierarchy_for_href #{result}" if @debugging

    result
  end

  # url related

  def title_for(hierarchy)
    if hierarchy[:subtitle].present?
      "#{hierarchy[:title]} CFR Subtitle #{hierarchy[:subtitle]}"
    elsif hierarchy[:chapter].present?
      "#{hierarchy[:title]} CFR Chapter #{hierarchy[:chapter]}"
    else
      "#{hierarchy[:title]} CFR"
    end
  end

  def part_or_section_string(hierarchy)
    return "/section-#{hierarchy[:section]}" if hierarchy[:section] && !hierarchy[:part]
    return "" unless hierarchy[:part]
    return "/part-#{hierarchy[:part]}/subpart-#{hierarchy[:subpart]}" if !hierarchy[:section] && hierarchy[:subpart]
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

  # utility

  def numbers_seem_like_a_range?(numbers)
    (numbers.count == 2) && numbers.all?(&:nonzero?) && numbers_similarish(numbers)
  end

  def numbers_similarish(numbers)
    numbers.all? { |n| n < 50 } ||
      ((numbers.max - numbers.min) < 50) ||
      (numbers.min > numbers.max * 0.5)
  end

  def only_whitespace?(text)
    text =~ /\A\s*\Z/
  end

  def drop_whitespace_and_italics(captures, which)
    if captures[which].present?
      captures[which] = captures[which].gsub(/\s+/, "").gsub(/<\/?em>/, "")
    end
  end

  def slide_left(captures, left, right)
    captures[left] = captures.values_at(left, right).compact.join
    captures.delete(right)
  end

  def slide_right(captures, left, right)
    captures[right] = captures.values_at(left, right).compact.join
    captures.delete(left)
    captures.delete(right) if captures[right]&.length == 0
  end
end
