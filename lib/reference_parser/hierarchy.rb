class ReferenceParser::Hierarchy
  RANKS = %i[subtitle chapter subchapter part subpart section paragraph]

  include ReferenceParser::HierarchyContainer

  def appears_incomplete?(captures: {})
    # ranks explictly listed by the replace definition are required
    result = RANKS.detect do |rank|
      context_expected.include?(rank) && !@data[rank].present?
    end

    # if the replace definiton lists "in_suffix" then ranks listed by name in the
    # suffix capture are expected (ie: in this chapter, in this part)
    if context_expected.include?(:in_suffix)
      RANKS.each do |rank|
        if captures[:suffix]&.downcase&.include?(rank.to_s)
          result ||= !@data[rank].present? && (!%i[chapter subchapter].include?(rank) || !@data[:section].present?)
          break if result
        end
      end
    end

    # title is always required
    result ||= !@data[:title].present?

    puts "hierarchy_appears_incomplete? #{result} #{@data}" if @debugging && result
    result
  end

  def take_missing_from_context(captures: {})
    determine_available_from_context(captures: captures).each do |rank|
      @data[rank] = context[rank] if context[rank].present? && !@data[rank].present?
    end
  end

  def cleanup!(expected: {})
    # drop any list or range related items that made it through
    if @data[:paragraph].present?
      @data[:paragraph].gsub!(ReferenceParser::HierarchyCaptures::LIST_EXAMPLES, "") if @data[:paragraph].include?("xample")
      @data[:paragraph].gsub!(/paragraph/i, "")
    end
    @data.transform_values! do |value|
      list_items = /(\s+|,|or|and|through)+/i
      value.gsub(/\A#{list_items}/, "") # prefixed whitespace / list items
        .gsub(/#{list_items}\z/, "") # suffixed whitespace / list items
    end

    # hierarchy shouldn't contain unknowns
    @data.reject! { |k, v| v.blank? }

    decide_section_vs_part(expected: expected)

    slide_right(:prefixed_subpart, :subpart)
    slide_right(:prefixed_paragraph, :paragraph)

    slide_right(:section, :appendix) if /\AAppendix/ix.match?(@data[:section])

    # drop list duplicated labels
    @data[:part]&.gsub!(/\s*part\s*/ix, "")

    if @data[:paragraph].present?
      @data[:paragraph].gsub!(/paragraph\s*/, "")
      @data[:paragraph] = @data[:paragraph].partition("through").first.strip if @data[:paragraph].include?("through")
    end

    self
  end

  def cleanup_list_ranges_if_needed!(repeated_capture: :section, processing_a_list: nil)
    effective_capture = repeated_capture
    effective_capture = :part if effective_capture == :section && !@data[effective_capture]
    value = @data[effective_capture]
    puts "cleanup_list_ranges_if_needed value #{value}" if @debugging
    if %i[section part paragraph].include?(effective_capture) && ((/\bto\b|through/ =~ value) || (value&.include?("-") && !(1 == value&.count("."))))
      items = value.split(/\bto\b|-|through/)
      if (effective_capture == :paragraph) || ReferenceParser::Guesses.numbers_seem_like_a_range?(items.map(&:to_i))
        puts "cleanup_list_ranges_if_needed AAA \"#{items.first}\"-\"#{items.last}\" <= \"#{value}\"" if @debugging
        @data[effective_capture] = items.first.to_s.strip
        @data["#{effective_capture}_end".to_sym] = items.last.to_s.strip
      end
    end
  end

  def normalize_paragraph_ranges(text: nil, previous_citation: nil, captures: {}, processing_a_list: nil)
    previous_hierarchy = previous_citation&.[](:hierarchy) || {}

    # paragraph is section+paragraph?
    if context[:mixed_paragraph_and_section_list] || (processing_a_list && starts_with_a_section?(@data[:paragraph], section: @data[:section]))
      context[:mixed_paragraph_and_section_list] = true
      puts "normalize_paragraph_ranges removing section #{captures[:section]}" if @debugging
      captures.delete(:section)

      if @data[:section].present? && @data[:paragraph]&.start_with?(@data[:section])
        puts "normalize_paragraph_ranges removing section prefix from paragraph #{@data[:paragraph]} #{@data[:section]}" if @debugging
        @data[:paragraph].delete_prefix!(@data[:section])
      else
        original_section = @data[:section]
        @data.delete(:section)
        repartition(:section, "(", :paragraph)
        @data[:section] = previous_hierarchy[:section] || original_section unless @data[:section].present?
        puts "normalize_paragraph_ranges replacing section #{@data[:section]}" if @debugging
      end
    elsif processing_a_list && ends_with_a_paragraph?(@data[:section], paragraph: @data[:paragraph])
      # section is section+paragraph?
      repartition(:section, "(", :paragraph)
      @data[:section] = previous_hierarchy[:section] || original_section unless @data[:section].present?
      @data[:section] = @data[:section].strip
      puts "normalize_paragraph_ranges [section is section+paragraph] #{@data[:section]} #{@data[:paragraph]}" if @debugging
    end

    # paragraph is section?
    move_paragraph_to_section = ((@data[:paragraph]&.count("(") || 0) == 0) && (@data[:paragraph]&.include?(".") || ReferenceParser::Guesses.numbers_seem_like_a_range?([@data[:paragraph], @data[:section]].compact))
    if move_paragraph_to_section
      # this seems like the list has jumped back up to sections
      @data[:section] = @data[:paragraph]
      @data.delete(:paragraph)
      puts "normalize_paragraph_ranges reverting paragraph to section #{@data[:section]} <= #{@data[:paragraph]}" if @debugging
    end

    if ((@data[:paragraph]&.count("(") || 0) == 1) &&
        ((previous_hierarchy[:paragraph]&.count("(") || 0) > 1) &&
        ((/and|or|through/ =~ text) || (/and|or|through/ =~ captures[:paragraph]))
      potential_prefix = previous_hierarchy[:paragraph].rpartition("(").first
      potential_update = potential_prefix + @data[:paragraph]
      if ReferenceParser::Paragraph.guess_level(@data[:paragraph]) != ReferenceParser::Paragraph.guess_level(potential_prefix.rpartition("(").last)
        puts "normalize_paragraph_ranges #{potential_update} <= #{@data[:paragraph]}" if @debugging
        @data[:paragraph] = potential_update
      elsif @debugging
        puts "normalize_paragraph_ranges ignored same levels #{potential_update} <=/= #{@data[:paragraph]}"
      end
    end

    # paragraphs rolled up into sections
    allow_rollup = captures[:rolled_up_paragraphs] || (captures[:source] != :cfr)
    if allow_rollup && @data[:section]&.start_with?("(") && !@data[:paragraph] &&
        (previous_citation.dig(:hierarchy, :section)&.include?("(") || previous_citation.dig(:hierarchy, :paragraph)&.include?("("))
      slide_right(:section, :paragraph)
      @data[:section] = previous_citation.dig(:hierarchy, :section).partition("(").first
    end
  end

  def starts_with_a_section?(paragraph, section: nil)
    return unless paragraph.present?
    match = /^A[\d[a-z].\-]+/ix.match(paragraph)
    match || (section && paragraph.start_with?(section)) || ((paragraph.index("(") || 0) > 0)
  end

  def ends_with_a_paragraph?(section, paragraph: nil)
    return unless section.present?
    match = /\([^T]\)\z/ix.match(section)
    match || (paragraph && section.end_with?(paragraph))
  end

  def to_href_hierarchy(expected: {})
    ReferenceParser::Hierarchy.new(@data.dup, options: @options, debugging: @debugging).cleanup_for_href
  end

  def cleanup_for_href(expected: {})
    if (@data[:section] && !@data[:part]) || (@data[:part] && !@data[:section])
      part_section = @data.values_at(:section, :part).join
      if part_section.include?(".")
        @data[:part], _, @data[:section] = part_section.partition(".")
      else
        unless expected[:section]
          @data[:part] = part_section
          @data.delete(:section)
          puts "cleanup_for_href deleting section" if @debugging
        end
      end
    end

    @data[:paragraph].gsub!(/\s*\(last\s*sentence\)\s*/ix, "") if @data[:paragraph].present?

    drop_whitespace_and_italics(:part)
    drop_whitespace_and_italics(:paragraph)
    drop_whitespace_and_italics(:section)

    @data[:part].tr!(",", "") if @data[:part].present?
    @data[:section].tr!(",", "") if @data[:section].present?

    if @data[:appendix].present?
      @data[:appendix] = "#{@data[:appendix]} to Part #{@data[:part]}".gsub(" ", "%20").gsub("appendix", "Appendix")
    end

    # from match 12 CFR § 275.206(a)(3)-3 expecting "/on/2021-05-17/title-12/section-275.206(a)(3)-3"
    slide_left(:section, :paragraph) if @data[:paragraph]&.include?("-")

    slide_right(:paragraph, :sublocators) # url uses "sublocators"

    puts "cleanup_for_href #{self}" if @debugging

    self
  end

  def finish!
    @data[:appendix].gsub!(/appendix/i, "").strip! if @data[:appendix].present?
  end

  private

  def determine_available_from_context(captures: {})
    results = []

    results << :title if context[:title] && !@data[:title].present? &&
      context_expected.include?(:title)

    results << :section if context[:section] && !@data[:section].present? &&
      (@data[:paragraph].present? || @data[:subpart].present?) &&
      (context_expected.include?(:section) ||
      context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("section"))

    if context[:chapter] && !@data[:chapter].present? &&
        (@data[:paragraph].present? || @data[:subpart].present? || @data[:part].present?) &&
        !@data[:section].present? && !results.include?(:section) &&
        (!context_expected.include?(:section) ||
        context_expected.include?(:in_suffix) && !captures[:suffix]&.downcase&.include?("subchapter") && captures[:suffix]&.downcase&.include?("chapter"))
      results << :chapter
    end

    if context[:chapter] && !@data[:chapter].present? &&
        context_expected.include?(:in_suffix) && !captures[:suffix]&.downcase&.include?("subchapter") && captures[:suffix]&.downcase&.include?("chapter")
      results << :chapter
    end

    if context[:subchapter] && !@data[:subchapter].present? &&
        (@data[:paragraph].present? || @data[:subpart].present? || @data[:part].present?) &&
        !@data[:section].present? && !results.include?(:section) &&
        ((!context_expected.include?(:section) && (!context_expected.include?(:chapter) && !results.include?(:chapter))) ||
        context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("subchapter"))
      results << :subchapter
    end

    results << :part if context[:part] && !@data[:part].present? &&
      (
        @data[:paragraph].present? ||
        @data[:subpart].present? ||
        (@data[:section].present? && !@data[:section]&.include?("."))
      ) &&
      (context_expected.include?(:part) ||
      context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("part"))

    puts "determine_available_from_context \"#{results}\" context_expected \"#{context_expected}\"" if @debugging
    results
  end

  def decide_section_vs_part(expected: {})
    if !@data[:part] && @data[:section]
      if @options[:prefer_part] && !@data[:section]&.include?(".")
        repartition(:part, ".", :section, drop_divider: true)
      elsif expected[:part]
        # take section if missing part & expecting it
        slide_left(:part, :section)
        slide_left(:part_end, :section_end)
      end
    end
  end
end
