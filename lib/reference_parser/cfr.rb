class ReferenceParser::Cfr < ReferenceParser::Base
  
  def link_options(citation)
    { class: "cfr external" }
  end

  # sub-patterns & utilities

  TITLE_CFR = /
    (?<title>\d+)                           # 42
    (?<cfr_label>\s*C\.?F\.?R\.?\s*)        # CFR
    /ix

  TITLE_CFR_ALLOW_SLASH_SHORTHAND = /
    (?<title>\d+)                           # 42
    (?<cfr_label>(\s*(C\.?F\.?R\.?)\s*|\/)) # CFR
    /ix

  NEXT_TITLE_STOP = /(?!\s*(C\.?F\.?R|U\.?S\.?C))/ix  # ...1 CFR 11 and 2 CFR 22...    vs    ...1 CFR 11 and 12.
                                                      # needed after simple digits patterns that could match the
                                                      # next title

  TRAILING_BOUNDRY = /(?!\d)/ix             # don't stop mid-number

  SUBTITLE_ID   = /([A-Z]{1,7})/ix
  CHAPTER_ID    = /(\d{1,5}|[A-Z]{1,7})/ix
  SUBCHAPTER_ID = CHAPTER_ID
  PART_ID       = /\d+/ix
  SUBPART_ID    = SUBTITLE_ID

  CHAPTER_LABEL    = /(?<chapter_label>\s*Ch(ap(ter)?)?\s*)/ix
  CHAPTER          = /(?<chapter>#{CHAPTER_ID})/ix
  SUBCHAPTER_LABEL = /(?<subchapter_label>\s*Subch(ap(ter)?)?\s*)/ix  
  SUBCHAPTER       = /(?<subchapter>#{SUBCHAPTER_ID})/ix  
  PART_LABEL       = /(?<part_label>\s*Part\s*)/ix
  PART             = /(?<part>#{PART_ID})/ix

  PARENTHETICALS = /
    ( \((<em>)?[a-z]{1,3}(<\/em>)?\)\s* |   # (a)(b)...
      \((<em>)?[\d]{1,3}(<\/em>)?\)\s*  |   # (1)(2)...
      \((<em>)?[xvi]{1,7}(<\/em>)?\)\s*     # (i)(iv)...
    ) 
    /ix

  OPTIONAL_PARENTHETICALS = /#{PARENTHETICALS}*/ix

  PARAGRAPH_UNLABELLED          = /\s*#{PARENTHETICALS}*(-\d+)?/ix
  PARAGRAPH_UNLABELLED_REQUIRED = /\s*#{PARENTHETICALS}+(-\d+)?/ix
  
  PARAGRAPH          = /(?<paragraph>#{PARAGRAPH_UNLABELLED})/ix
  PARAGRAPH_REQUIRED = /(?<paragraph>#{PARAGRAPH_UNLABELLED_REQUIRED})/ix
  
  PARAGRAPHS = /
    (?<paragraphs>                          # list of paragraphs
      (
        #{PARAGRAPH_UNLABELLED_REQUIRED}
        ((\s|,|and|through)+#{PARAGRAPH_UNLABELLED_REQUIRED})*
      )
    )
    /ix

  EXAMPLES = /
    (
      (<em>)?\s*Examples?\s*\d+(<\/em>)?(\s*through\s*|\s*,\s*(and\s*)?)?      # Example 28, Example 29, and Example 30 
    )+    
    /ix   
    
  EXPANDED_PARAGRAPHS = /
    (?<paragraph_prefix>
      \s*and\s*
      #{EXAMPLES}                           #
      \s*in\s*paragraph\s*
    )?
    (?<paragraphs>                          # list of paragraphs
      (
        #{PARAGRAPH_UNLABELLED_REQUIRED}
        (\s\(last\ssentence\))?
        ((\s|,|and|through)+#{PARAGRAPH_UNLABELLED_REQUIRED})*
      )
    )
    /ix

  PARAGRAPH_EXAMPLE_PREFIX = /
    (<em>)?\s*Examples?\s*.                          # required example text
    (
      (<em>)?\s*(Examples?\s*)?                      # optional italics and or repeated example test
      \d+                                            # number
      (<\/em>)?                                      # close italics if needed
      (\s*through\s*|\s*,\s*(and\s*)?)?  
    )+                                               # allow a list of examples
    (\s*in\s*)?                                      # in
    /ix

  SECTION_UNLABELLED = /
    \d+#{NEXT_TITLE_STOP}(\.\d+)?#{NEXT_TITLE_STOP}([a-z]\d?)?
    #{OPTIONAL_PARENTHETICALS}            
    (
      (-\d+T?)| # dash suffix if present tends to mark end of section area
      (\.\d+) |
      (\(T\))   # temporary may be marked w T suffix
    )*
    \s*#{NEXT_TITLE_STOP}
    
    /ix 

  SECTION = /(?<section>#{SECTION_UNLABELLED})/ix

  SECTIONS = /
    (?<sections>
      #{SECTION_UNLABELLED}
      (
        \s*(?!CFR)(,|(,\s*|)and|(,\s*|)or|through)\s*   # join
        #{SECTION_UNLABELLED}                           # additional sections
      )*
    )
    /ix


  # reference replacements

  replace(/
      #{TITLE_CFR}                                     # title 
      (?<part_label>part\s*)(?<part>\d+)               # labelled part
      (?<subpart_label>,?\s*subpart\s*)(?<subpart>[A-Z]) # labelled subpart
    /ix)

  replace(/
      #{TITLE_CFR}                                     # title 
      (?<chapter_label>chapter\s*)                     # labelled chapter
      (?<chapter>[A-Z]+\s*)      
    /ix)

  replace(/
      #{TITLE_CFR}
      (?<part_label>parts?\s*)?
      (?<section_label>(§+|sec\.?(tion)?)\s*)?
      #{SECTIONS}
      #{PARAGRAPH}
      #{TRAILING_BOUNDRY}
    /ix)


  # partial reference replacements (of this ...)

  replace(/
    (?<chapter_label>chapter\s*)(?<chapter>[A-Z]+)   # chapter - required
    (?<suffix>\s*of\s*this\s*title)                  # of this title
    /ix, if: :context_present?, context_usable: :title)
  
  replace(/
    (?<subtitle_label>subtitle\s*)(?<subtitle>[A-Z]) # subtitle - required
    (?<suffix>\s*of\s*this\s*title)                  # of this title
    /ix, if: :context_present?, context_usable: :title)

  replace(/
    ((?<prefixed_subpart_label>subpart\s*)(?<prefixed_subpart>[A-Z]+)
    (?<prefixed_subpart_connector>\s*of\s*))?        # subpart C of...
    (?<part_label>part\s*)(?<part>\d+)               # part - required
    (
      (?<subpart_label>\s*,\s*subpart\s*)(?<subpart>[A-Z]+) # part 30, subpart A of this chapter
    )?            
    (?<suffix>\s*of\s*this\s*(title|chapter))        # of this title.chapter
    /ix, if: :context_present?, context_usable: %i'title in_suffix')

  replace(/
    (
      (?<subpart_label>\s*subpart\s*)(?<subpart>[A-Z]+) # subpart
      |
      (?<section>(?<appendix_label>\s*appendix\s*)[A-Z]+) # appendix
    )
    (?<suffix>\s*of\s*this\s*part)                   # of this part
    /ix, if: :context_present?, context_usable: %i'title part')

  
  MESSY_TRAILING_BOUNDRY = /
    (?!\s?of\stitle\s\d+,\sUnited\sStates\sCode)     # for standalone section
    (?!\d)
    /ix  

  replace(/
    (?<![>"])                                        # avoid matching start of tag for section header
    (
      (?<prefixed_paragraph_label>paragraph\s*)
      (?<prefixed_paragraph>#{PARAGRAPH_UNLABELLED})
      (?<prefixed_paragraph_suffix>\s*of\s*)
    )?
    (?<section_label>(§+|section)\s*)#{SECTIONS}
    #{PARAGRAPH}                                     # 
    (?<suffix>\s*(of\s*this\s*(title|chapter))?)
    #{MESSY_TRAILING_BOUNDRY}
    /ix, if: :context_present?, context_usable: :title)

  # local list of paragraphs
  #   paragraph (b)(2)(iv)(<em>d</em>)(<em>4</em>), 
  #   ...
  #   and <em>Examples 31</em> through <em>35</em> in paragraph (b)(5) 
  #   of this section
  replace(/
    (?<paragraphs>        
      (
        (#{PARAGRAPH_EXAMPLE_PREFIX})?
        paragraph\s*
        #{PARAGRAPH_UNLABELLED}
        (,\s*(and\s*)?)?
      )+
    )
    (?<suffix>
          \s*of\sthis\ssection
    )
    /ix, if: :context_present?, context_usable: %i'title section')

  # expanded preable local list of paragraphs
  replace(/
    (?<paragraph_label>paragraphs?\s*)
    #{EXPANDED_PARAGRAPHS}
    (?<suffix>
      (#{EXAMPLES})?
      \s*of\sthis\ssection
    )
    /ix, if: :context_present?, context_usable: %i'title section')


  # primarly list replacements

  replace(->(context, options){
    /
    #{options[:slash_shorthand_allowed] || options[:best_guess] ? TITLE_CFR_ALLOW_SLASH_SHORTHAND : TITLE_CFR}
    #{SECTIONS}
    #{PARAGRAPH}
    #{TRAILING_BOUNDRY}
    /ix
  }, prepend_pattern: true)


  # context specific patterns

  replace(->(context, _){
    return unless context[:section].present? && context[:section].include?(".") && (3 < context[:section].length)
    /
    (?<!(=('|")p-|§\s))                              # properly labelled can be matched by non-context pattern, avoid tags
    (?<section>#{Regexp.escape(context[:section])})  # current section anchor
    (?<paragraph>
      #{PARAGRAPH}
    )
    /ix
  }, if: :context_present?, context_usable: :title)
    

  # best guess fallback patterns

  replace(->(context, options){
    return unless options[:best_guess]
    /
    #{TITLE_CFR_ALLOW_SLASH_SHORTHAND}
    /ix
  }, prepend_pattern: true)

  replace(->(context, options){
    return unless options[:best_guess]
    /
    (?<title_label>Title\s*)(?<title>\d+)            # title pattern anchor
    (#{CHAPTER_LABEL}#{CHAPTER})?
    (#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (#{PART_LABEL}#{PART})?
    ((?<section_label>\s*§\s*)#{SECTION})?
    /ix
  })

  replace(->(context, options){
    return unless options[:best_guess]
    /
    (?<title>\d+)                                    # title unlabelled
    #{CHAPTER_LABEL}#{CHAPTER}                       # chapter pattern anchor
    (#{SUBCHAPTER_LABEL}#{SUBCHAPTER})?
    (#{PART_LABEL}#{PART})?
    ((?<section_label>\s*(\/|§)\s*)#{SECTION})?         # allow slash shorthand for best guess
    /ix
  })

  def context_present?(options)
    options[:context].present?
  end

  def url(citation, url_options={})
    return unless citation
    citation = citation[:href_hierarchy] || citation[:hierarchy] || (citation&.include?(:title) ? citation : {})    
    result = ""
    result << "https://ecfr.federalregister.gov" if absolute?(url_options)
    result << url_current_compare_or_on(url_date_from_options(url_options || {}))
    result << "/title-#{citation[:title]}"
    result << url_messy_part(citation)
    result
  end

  def url_date_from_options(url_options={})
    current = url_options[:current] ? :current : nil
    on      = url_options[:on]
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
      "/compare/#{date.map{ |endpoint| endpoint.respond_to?(:to_formatted_s) ? endpoint.to_formatted_s(:iso) : endpoint }.join("/to/")}"
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

  EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS = %i'
    prefix
    prefixed_subpart_label prefixed_subpart prefixed_subpart_connector 
    prefixed_paragraph_label prefixed_paragraph prefixed_paragraph_suffix
    title_label title cfr_label 
    subtitle_label subtitle 
    chapter_label chapter 
    subchapter_label subchapter
    part_label part 
    subpart_label subpart 
    section_label section none
    paragraph_label paragraph paragraph_range_end
    suffix'


  def clean_up_named_captures(captures, options: {})
    results = []

    context = prepare_context(options)
    
    usable = [options&.[](:context_usable)].flatten
    captures = prepare_captures(captures)

    
    expected = { # determine expected captures
      subtitle:   captures[:subtitle_label].present?,
      subchapter: captures[:subchapter_label].present?,
      part:       captures.values_at(*%i'part_label appendix_label').detect(&:present?),
      subpart:    captures.values_at(*%i'prefixed_subpart_label subpart_label').detect(&:present?),
      section:    captures[:section_label].present?,
    }


    # determine repeated capture (if any)
    repeated = [captures[:sections] || captures[:section]].flatten.select(&:present?)
    repeated_capture = :section
    if !repeated.present? && captures[:paragraphs].present?
      repeated = [captures[:paragraphs] || captures[:paragraph]].flatten.select(&:present?)
      repeated_capture = :paragraph
    end
    repeated_capture, repeated  = :none, [""] unless repeated.present?
    slide_left(captures, :paragraph, :paragraphs) if repeated != :paragraph
    processing_a_list = (1 < repeated.count) || captures[:part_label]&.include?("parts")


    # partition the available capture groups into a prefix set and suffix set based 
    # on the position of the repeated capture (if any)
    index = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS.find_index(repeated_capture)
    first_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[0..index]
    last_loop_named_captures = EXPECTED_ORDER_OF_APPEARANCE_FOR_CAPTURE_GROUPS[index..-1]
      
    repeated&.each_with_index do |what, index|
      loop_captures = { repeated_capture => what }.reverse_merge(captures.except(:prefix, :suffix))
      prepare_loop_captures(loop_captures, processing_a_list: processing_a_list)


      # build hierarchy
      hierarchy_elements = %i'title chapter'
      hierarchy_elements << :subchapter if expected[:subchapter]
      hierarchy_elements.concat(%i'section part')
      hierarchy_elements << :subtitle if expected[:subtitle]
      hierarchy_elements.concat(%i'subpart prefixed_subpart') if expected[:subpart]
      hierarchy_elements << :part if expected[:part]
      hierarchy_elements.concat(%i'paragraph prefixed_paragraph')
      hierarchy = loop_captures.slice(*hierarchy_elements)


      if options[:context_usable].present?
        # fill in hierarchy from context (if needed)
        available_from_context = determine_available_from_context(hierarchy, context: context, usable: usable, captures: captures)
        available_from_context.each do |k|
          hierarchy[k] = context[k] if context[k].present? && !hierarchy[k].present?
        end
      end
      next unless hierarchy[:title].present?


      # reassemble text for link
      text_from_captures = (!processing_a_list || (0 == index)) ? first_loop_named_captures : []  # first loop/prefix
      text_from_captures << repeated_capture
      text_from_captures.concat(last_loop_named_captures) if (index == (repeated.count - 1))        # last loop/suffix

      loop_prefix = (index == 0) ? captures[:prefix] || "" : ""
      loop_suffix = (index == (repeated.count - 1)) ? captures[:suffix] || "" : ""

      text = (loop_prefix || "") + loop_captures.slice(*text_from_captures).values.join + (loop_suffix || "")      


      # cleanup hierarchy
      hierarchy = cleanup_hierarchy(hierarchy, expected: expected)
      hierarchy = cleanup_hierarchy_for_list_ranges_if_needed(hierarchy, repeated_capture: repeated_capture, processing_a_list: processing_a_list)
      href_hierarchy = cleanup_hierarchy_for_href(hierarchy, expected: expected)


      # build citation      
      citation = { hierarchy:      hierarchy,
                   href_hierarchy: href_hierarchy,
                   text:           text }
                   
                   
      results << citation
    end

    results
  end

  def split_lists_into_individual_items(captures, keys, simple: false)
    keys.each do |key|
      original = captures[key]
      next unless original.present?
      clean = captures[key].dup

      specific_all_dividers = nil
      specific_all_dividers = /(?<split>(,|\s+|and|or|through|#{PARAGRAPH_EXAMPLE_PREFIX})+)/ix if key == :paragraphs
      
      if simple
        # look-behind includes match in split (instead of discarding)
        clean[key] = clean[key]&.split(/(?<=(?:,|through|or|and))/)
      else
        # split on any list markers, then absorb into values prefering
        # commas to the left and connectors to the right        
        any_divider = /(?<split>(\s*(,|and|or|through)\s*))/ix
        all_dividers = specific_all_dividers || /(?<split>(,|\s+|and|or|through)+)/ix
        trailing_dividers = /and|or|through/ix
        z = 0
        if split = clean&.split(any_divider)&.select{ |s| s.length > 0 }
          x = 1
          while x < (split.length - 1)
            # puts "split z #{z} x #{x} split #{split}" if @debugging
            if split[x] =~ /\A#{all_dividers}\z/i # only list cruft
              if (split[x] =~ trailing_dividers) && (x < (split.length - 1))
                split[x+1] = split[x] + split[x+1]
              else
                split[x-1] = split[x-1] + split[x]
              end
              split.delete_at(x)
            else
              x += 1
            end
          end
          captures[key] = split if 1 < split.count
        end
      end
      puts "split original \"#{original}\" into \"#{captures[key]}\"" if @debugging && original != captures[key] if @debugging
    end
  end
  
  def determine_available_from_context(hierarchy, context: {}, usable: [], captures: {})
    results = []
    
    results << :title   if context[:title] && !hierarchy[:title].present? && 
                           usable.include?(:title)

    results << :section if context[:section] && !hierarchy[:section].present? && 
                           (hierarchy[:paragraph].present? || hierarchy[:subpart].present?) &&
                           (usable.include?(:section) ||
                            usable.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("section"))

    results << :part    if context[:part] && !hierarchy[:part].present? && 
                           (
                             hierarchy[:paragraph].present? || 
                             hierarchy[:subpart].present? ||
                             (hierarchy[:section].present? && !hierarchy[:section]&.include?(".")) 
                           ) &&
                           (usable.include?(:part) ||
                            usable.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("part"))

    puts "determine_available_from_context \"#{results}\" usable \"#{usable}\"" if @debugging
    results
  end

  def prepare_captures(captures)
    captures = captures.select{ |k,v| v }.symbolize_keys

    slide_right(captures, :paragraph, :suffix) if only_whitespace?(captures[:paragraph])

    split_lists_into_individual_items(captures, %i'sections paragraphs')
    slide_left(captures, :section, :part_string)

    restore_paragraph(captures)

    captures
  end

  def prepare_loop_captures(captures, processing_a_list: false)
    restore_paragraph(captures) unless processing_a_list
  end

  def restore_paragraph(captures)
    # sections aren't expected to have parentheticals w/out a dashed suffix
    if captures[:section]&.include?("(") and !captures[:section]&.include?("-")
      repartition(captures, :section, "(", :paragraph)
    end
  end

  def repartition(captures, left, pivot, right, drop_divider: false)
    left_value, pivot_value, right_value = captures.values_at(left, right).compact.join.partition(pivot)
    right_value = [pivot_value, right_value].compact.join unless drop_divider
    if 0 < left_value.length
      captures[left] = left_value
    else
      captures.delete(left)
    end
    if 0 < right_value.length
      captures[right] = right_value
    else
      captures.delete(right)
    end
  end

  def prepare_context(options)
    result = options&.[](:context) || {}
    if composite_hierarchy = options&.[](:composite_hierarchy) || result[:composite_hierarchy]
      result.reverse_merge!(%i'title subtitle chapter subchapter part subpart section_identifier'.zip(composite_hierarchy.split(/:/)).to_h)
    end
    result || {}
  end


  def cleanup_hierarchy(hierarchy, expected: {})
    puts "cleanup_hierarchy AAA hierarchy #{hierarchy}" if @debugging
    result = hierarchy

    # drop any list or range related items that made it through
    if result[:paragraph].present?
      result[:paragraph].gsub!(PARAGRAPH_EXAMPLE_PREFIX, "") if result[:paragraph].include?("xample")
    end
    result.transform_values! do |value| 
      list_items = /(\s+|,|or|and|through)+/i
      value.gsub(/\A#{list_items}/, ""). # prefixed whitespace / list items
            gsub(/#{list_items}\z/, "")  # suffixed whitespace / list items
    end

    # hierarchy shouldn't contain unknowns
    result.reject!{ |k,v| v.blank? }

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
      else
        # take section if missing part & expecting it
        if expected[:part] 
          slide_left(hierarchy, :part, :section)
        end
      end
    end
  end

  def cleanup_hierarchy_for_list_ranges_if_needed(hierarchy, repeated_capture: :section, processing_a_list: nil)
    effective_capture = repeated_capture
    effective_capture = :part if effective_capture == :section && !hierarchy[effective_capture]
    if processing_a_list && %i'section part'.include?(effective_capture) && hierarchy[effective_capture]&.include?("-") && !hierarchy[effective_capture]&.include?(".")
      items = hierarchy[effective_capture].split("-").map(&:to_i)
      if numbers_seem_like_a_range?(items)
        puts "cleanup_hierarchy_for_list_ranges_if_needed AAA \"#{items.first.to_s}\"-\"#{items.last.to_s}\" <= \"#{hierarchy[effective_capture]}\"" if @debugging
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
        a, b, c = part_section.partition(".")
        result[:part] = a
        result[:section] = c
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
    return "/part-#{hierarchy[:part]}" if !hierarchy[:section]
    "/section-#{hierarchy[:part]}.#{hierarchy[:section]}"
  end

  def sublocators_string(hierarchy)
    return "" unless hierarchy[:sublocators]
    result = "#p-#{hierarchy[:part]}"
    result << "." if hierarchy[:part] && hierarchy[:section]
    result << "#{hierarchy[:section]}" if hierarchy[:section]
    result << "#{hierarchy[:sublocators]}"
  end


  # utility

  def numbers_seem_like_a_range?(numbers)
    (numbers.count == 2) && numbers.all?(&:nonzero?) && numbers_similarish(numbers)
  end

  def numbers_similarish(numbers)
    numbers.all?{ |n| n < 50} ||
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
