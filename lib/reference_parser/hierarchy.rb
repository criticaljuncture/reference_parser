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
          result ||= !@data[rank].present? && (!%i[chapter].include?(rank) || !@data[:section].present?)
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

    if @data[:paragraph].present?
      @data[:paragraph].gsub!(/paragraph\s*/, "")
      @data[:paragraph] = @data[:paragraph].partition("through").first.strip if @data[:paragraph].include?("through")
    end

    self
  end

  def cleanup_list_ranges_if_needed!(repeated_capture: :section, processing_a_list: nil)
    effective_capture = repeated_capture
    effective_capture = :part if effective_capture == :section && !@data[effective_capture]
    if %i[section part paragraph].include?(effective_capture) && @data[effective_capture]&.include?("-") && !@data[effective_capture]&.include?(".")
      items = @data[effective_capture].split("-")
      if (effective_capture == :paragraph) || ReferenceParser::Guesses.numbers_seem_like_a_range?(items.map(&:to_i))
        puts "cleanup_hierarchy_for_list_ranges_if_needed AAA \"#{items.first}\"-\"#{items.last}\" <= \"#{@data[effective_capture]}\"" if @debugging
        @data[effective_capture] = items.first.to_s
        @data["#{effective_capture}_end".to_sym] = items.last.to_s
      end
    end
  end

  def normalize_paragraph_ranges(text: nil, previous_citation: nil, captures: {})
    return unless previous_citation
    previous_hierarchy = previous_citation[:hierarchy]
    if ((@data[:paragraph]&.count("(") || 0) == 0) &&
        (@data[:paragraph]&.include?(".") || ReferenceParser::Guesses.numbers_seem_like_a_range?([@data[:paragraph], @data[:section]].compact))
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
    if captures[:rolled_up_paragraphs] && @data[:section]&.start_with?("(") && !@data[:paragraph] && previous_citation.dig(:hierarchy, :section)&.include?("(")
      slide_right(:section, :paragraph)
      @data[:section] = previous_citation.dig(:hierarchy, :section).partition("(").first
    end
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
          puts "cleanup_hierarchy_for_href deleting section" if @debugging
        end
      end
    end

    @data[:paragraph].gsub!(/\s*\(last\s*sentence\)\s*/ix, "") if @data[:paragraph].present?

    drop_whitespace_and_italics(:paragraph)

    # from match 12 CFR § 275.206(a)(3)-3 expecting "/on/2021-05-17/title-12/section-275.206(a)(3)-3"
    slide_left(:section, :paragraph) if @data[:paragraph]&.include?("-")

    slide_right(:paragraph, :sublocators) # url uses "sublocators"

    puts "cleanup_hierarchy_for_href #{self}" if @debugging

    self
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
        context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("chapter"))
      results << :chapter
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
      end
    end
  end
end
