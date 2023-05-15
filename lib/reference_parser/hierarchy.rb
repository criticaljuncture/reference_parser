class ReferenceParser::Hierarchy
  RANKS = %i[title subtitle chapter subchapter part subpart subject_group section appendix]

  PARSED_RANKS = RANKS - %i[title subject_group appendix] + %i[paragraph]

  GENERATED_LEVEL_PATTERN = /ECFR[\da-z]+/

  include ReferenceParser::HierarchyContainer

  def self.citation(hierarchy, alias_hierarchy: nil, alias_text: nil, build_id: nil, current: true, date_format: nil, short: false, title_date: nil)
    citation = []

    prefix = (alias_text || "Title #{hierarchy[:title]}")
    hierarchy = hierarchy.except(*alias_hierarchy.keys) if alias_hierarchy.present?
    citation << prefix

    case ReferenceParser::Hierarchy.deepest_level_in(hierarchy, ignore_generated: true)
    when :title
      citation = [alias_hierarchy || "Title #{hierarchy[:title]} of the CFR"]
    when :subtitle
      citation << "Subtitle #{hierarchy[:subtitle]}"
    when :chapter, :subchapter
      if hierarchy[:chapter]
        citation << "Chapter #{hierarchy[:chapter]}"
      elsif hierarchy[:subtitle]
        citation << "Subtitle #{hierarchy[:subtitle]}"
      end
      citation << "Subchapter #{hierarchy[:subchapter]}" if hierarchy[:subchapter].present?
    when :part, :subpart, :subject_group
      citation << "Part #{hierarchy[:part]}" unless hierarchy[:subpart].present? && hierarchy[:subpart].start_with?(hierarchy[:part])
      citation << "Subpart #{hierarchy[:subpart]}" if hierarchy[:subpart].present?
      citation << " - #{hierarchy[:subject_group]}" if hierarchy[:subject_group].present? && !short
    when :section
      citation << hierarchy[:section]
    when :appendix
      citation = ["#{hierarchy[:appendix]},", prefix]
    end

    case date_format
    when :proper
      if build_id.present?
        citation << " (for build #{build_id})"
      else
        reference_date = hierarchy.date.to_date
        citation << if reference_date < title_date
          " (in effect on #{reference_date.to_formatted_s(:us_standard)})"
        else
          " (up to date as of #{title_date.to_formatted_s(:us_standard)})"
        end
      end
    else
      citation << " (#{hierarchy.date})" unless current
    end

    citation.join(" ")
  end

  def self.deepest_level_in(hierarchy, ignore_generated: false)
    return if hierarchy.blank?
    return :paragraph if hierarchy[:paragraph].present?

    RANKS.reverse.detect do |level|
      hierarchy[level].present? && (!ignore_generated || !GENERATED_LEVEL_PATTERN.match?(hierarchy[level]))
    end
  end

  def self.truncate(hierarchy, rank)
    hierarchy.slice(*ReferenceParser::Hierarchy.levels_at_or_above(rank))
  end

  def self.hash_from_composite(composite)
    return {} unless composite.present?

    hierarchy_from_composite = %i[title subtitle chapter subchapter part subpart section_identifier]
      .zip(composite.split(":")).to_h

    hierarchy_from_composite.delete_if { |k, v| v.blank? }
    if hierarchy_from_composite[:section_identifier]
      rank = /(appendix|\s)/i.match?(hierarchy_from_composite[:section_identifier]) ? :appendix : :section
      hierarchy_from_composite[rank] = hierarchy_from_composite[:section_identifier]
    end

    hierarchy_from_composite
  end

  def self.levels_at_or_above(rank)
    RANKS[0..RANKS.index(rank)]
  end

  def appears_incomplete?(captures: {})
    # ranks explictly listed by the replace definition are required
    result = PARSED_RANKS.detect do |rank|
      result = context_expected.include?(rank) && !@data[rank].present?
      result = false if result && ((rank == :section) && @data[:appendix].present?)
      result
    end

    # if the definition lists "in_suffix" then ranks listed by name in the
    # suffix capture are expected (ie: in this chapter, in this part)
    if context_expected.include?(:in_suffix)
      section_disposable_ranks = %i[chapter subchapter subpart]
      PARSED_RANKS.each do |rank|
        if captures[:suffix]&.downcase&.include?(rank.to_s)
          if !@data[rank].present? && # missing the listed rank
              !(section_disposable_ranks.include?(rank) && @data[:section].present?) && # section makes several ranks disposable
              !@potentially_misleading.include?(rank) # intentionally excluded
            result ||= rank
          end
          break if result
        end
      end
    end

    # title is always required
    result ||= :title unless @data[:title].present? || captures[:alias_hierarchies]&.detect { |hierarchy| hierarchy[:title].present? }

    puts "hierarchy_appears_incomplete? #{result} #{@data}" if @debugging && result
    result
  end

  def take_missing_from_context(captures: {})
    determine_available_from_context(captures: captures).each do |rank, reason|
      if context[rank].present? && !@data[rank].present?
        if reason == :potentially_misleading
          @potentially_misleading << rank
        else
          @data[rank] = context[rank]
        end
      end
    end
  end

  def cleanup!(expected: {}, captures: {})
    # drop any list or range related items that made it through
    if @data[:paragraph].present?
      @data[:paragraph].gsub!(ReferenceParser::HierarchyCaptures::LIST_EXAMPLES, "") if @data[:paragraph].include?("xample")
      @data[:paragraph].gsub!(/(?:sub)?paragraph/i, "")
    end
    @data.transform_values! do |value|
      list_items = /(\s+|,|;|:|or|and|through)+/i
      value.gsub(/\A#{list_items}/, "") # prefixed whitespace / list items
        .gsub(/#{list_items}\z/, "") # suffixed whitespace / list items
    end

    # hierarchy shouldn't contain unknowns
    @data.reject! { |k, v| v.blank? }

    @data[:title]&.gsub!(/\A0+/, "")

    decide_section_vs_part(expected: expected)

    slide_right(:prefixed_part, :part)
    slide_right(:prefixed_subpart, :subpart)
    slide_right(:prefixed_paragraph, :paragraph)

    # correct delimiting labels
    if @data[:section]&.match?(/\Aappendices/ix)
      @data[:section]&.gsub!(/\Aappendices/ix, "appendix")
      expected[:section_list_appendix_toggle] = true
    elsif expected[:section_list_appendix_toggle] && @data[:section]&.match?(/\A#{ReferenceParser::Cfr::APPENDIX_ID}\z/ixo)
      @data[:section] = "Appendix #{@data[:section]}"
    end

    slide_right(:section, :appendix) if expected[:appendix] || expected[:section_list_appendix_toggle] || /\A(Appendix|Table)/ix.match?(@data[:section])
    slide_right(:appendix, :table) if /Table/ix.match?(captures[:appendix_label])

    # drop list duplicated labels
    @data[:part]&.gsub!(/\s*parts?\s*/ix, "")
    @data[:section]&.gsub!(/\A§§\s*/x, "")

    @data.delete(:subpart) if @data[:appendix].present? && expected[:section_list_appendix_toggle]

    if @data[:paragraph].present?
      @data[:paragraph].gsub!(/(?:sub)?paragraph\s*/, "")
      @data[:paragraph] = @data[:paragraph].partition("through").first.strip if @data[:paragraph].include?("through")
    end

    slide_likely_paragraph_right(:section, :paragraph)

    @data.transform_values! { |value| ReferenceParser::Dashes.ascii(value) }

    self
  end

  def cleanup_list_ranges_if_needed!(repeated_capture: :section, processing_a_list: nil)
    range_captures = %i[section part paragraph]
    effective_capture = repeated_capture
    effective_capture = :part if effective_capture == :section && !@data[effective_capture]
    [effective_capture, :paragraph].uniq.each do |effective_capture|
      value = @data[effective_capture]
      next unless value.present?
      puts "cleanup_list_ranges_if_needed value #{value}" if @debugging
      if range_captures.include?(effective_capture) && ((/\bto\b|through/ =~ value) || (value&.include?("-") && !(value&.count(".") == 1)))
        items = value.split(/\bto\b|-|through/)
        if (effective_capture == :paragraph) || ReferenceParser::Guesses.numbers_seem_like_a_range?(items.map(&:to_i))
          puts "cleanup_list_ranges_if_needed AAA \"#{items.first}\"-\"#{items.last}\" <= \"#{value}\"" if @debugging
          @data[effective_capture] = items.first.to_s.strip
          @data["#{effective_capture}_end".to_sym] = items.last.to_s.strip
        end
      end
    end
  end

  def normalize_paragraph_ranges(text: nil, previous_citation: nil, captures: {}, processing_a_list: nil)
    previous_hierarchy = previous_citation&.[](:hierarchy) || {}

    # paragraph is section+paragraph?
    if options[:mixed_paragraph_and_section_list] || (processing_a_list && starts_with_a_section?(@data[:paragraph], section: @data[:section]))
      options[:mixed_paragraph_and_section_list] = true
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
      @data[:section] = @data[:section]&.strip
      puts "normalize_paragraph_ranges [section is section+paragraph] #{@data[:section]} #{@data[:paragraph]}" if @debugging
    end

    # paragraph is section?
    move_paragraph_to_section = ((@data[:paragraph]&.count("(") || 0) == 0) && (@data[:paragraph]&.include?(".") || ReferenceParser::Guesses.numbers_seem_like_a_range?([@data[:paragraph], @data[:section]].compact))
    if move_paragraph_to_section
      # this seems like the list has jumped back up to sections
      @data[:section] = @data[:paragraph]
      @data.delete(:paragraph)
      if @data[:paragraph_end].present?
        @data[:section_end] = @data[:paragraph_end]
        @data.delete(:paragraph_end)
      end
      puts "normalize_paragraph_ranges reverting paragraph to section #{@data[:section]} <= #{@data[:paragraph]}" if @debugging
    end

    normalize_paragraph_ranges_incorporate_prior(update: :paragraph, prior_example: previous_hierarchy[:paragraph], text: text, captures: captures)
    normalize_paragraph_ranges_incorporate_prior(update: :paragraph_end, prior_example: @data[:paragraph], text: text, captures: captures)

    # paragraphs rolled up into sections
    allow_rollup = captures[:rolled_up_paragraphs] || (options[:source] != :cfr)
    if allow_rollup && @data[:section]&.start_with?("(") && !@data[:paragraph] &&
        (previous_hierarchy[:section]&.include?("(") || previous_hierarchy[:paragraph]&.include?("("))
      slide_right(:section, :paragraph)
      @data[:section] = previous_hierarchy[:section].partition("(").first
    end
  end

  def normalize_paragraph_ranges_incorporate_prior(prior_example:, text:, captures:, update: nil)
    if ((@data[update]&.count("(") || 0) == 1) &&
        ((prior_example&.count("(") || 0) > 1) &&
        (
          ((/and|or|through/ =~ text) || (/and|or|through/ =~ captures[update])) ||
          update.to_s.end_with?("_end")
        )
      potential_prefix = prior_example.rpartition("(").first
      potential_update = potential_prefix + @data[update]
      if ReferenceParser::Paragraph.guess_level(@data[update]) != ReferenceParser::Paragraph.guess_level(potential_prefix.rpartition("(").last)
        puts "normalize_paragraph_ranges #{potential_update} <= #{@data[update]}" if @debugging
        @data[update] = potential_update
      elsif @debugging
        puts "normalize_paragraph_ranges ignored same levels #{potential_update} <=/= #{@data[update]}"
      end
    end
  end

  def starts_with_a_section?(paragraph, section: nil)
    return unless paragraph.present?
    match = /^A[\d[a-z].-]+/ix.match(paragraph)
    match || (section && paragraph.start_with?(section)) || ((paragraph.index("(") || 0) > 0)
  end

  def ends_with_a_paragraph?(section, paragraph: nil)
    return unless section.present?
    match = /\([^T]\)\z/ix.match(section)
    match || (paragraph && section.end_with?(paragraph))
  end

  def to_href_hierarchy(expected: {}, captures: {})
    ReferenceParser::Hierarchy.new(@data.dup, options: @options, debugging: @debugging).cleanup_for_href(expected: expected, captures: captures)
  end

  def cleanup_for_href(expected: {}, captures: {})
    if (@data[:section] && !@data[:part]) || (@data[:part] && !@data[:section])
      part_section = @data.values_at(:section, :part).join
      if part_section.include?(".")
        @data[:part], _, @data[:section] = part_section.partition(".")
      else
        unless expected[:section]
          @data[:part] = part_section
          @data.delete(:section)
          puts Rainbow("cleanup_for_href deleting section").orange if @debugging
        end
      end
    end

    @data[:paragraph].gsub!(/\s*\(last\s*sentence\)\s*/ix, "") if @data[:paragraph].present?
    @data[:part].gsub!(" note", "") if @data[:part]&.end_with?(" note")

    drop_whitespace_and_italics(:part)
    drop_whitespace_and_italics(:paragraph)
    drop_whitespace_and_italics(:section)

    @data[:part].tr!(",", "") if @data[:part].present?
    @data[:section].tr!(",", "") if @data[:section].present?

    if @data[:appendix].present? || @data[:table].present?
      appendix = @data[:appendix] || @data[:table]
      appendix_label_values = captures.values_at(*%i[appendix_label]).join
      appendix = (appendix_label_values + appendix).strip if appendix_label_values.present?
      appendix = appendix.strip.delete_prefix(",").strip
      appendix << " to Part #{@data[:part]}" if @data[:part].present?
      appendix << ", Subpart #{@data[:subpart]}" if @data[:subpart].present? && @data[:table].present?
      @data[:appendix] = appendix.to_s.gsub(" ", "%20").gsub("appendix", "Appendix")
    end

    # from match 12 CFR § 275.206(a)(3)-3 expecting "/on/2021-05-17/title-12/section-275.206(a)(3)-3"
    slide_left(:section, :paragraph) if ReferenceParser::Dashes::ANY.match?(@data[:paragraph])

    slide_right(:paragraph, :sublocators) # url uses "sublocators"

    puts Rainbow("cleanup_for_href #{self}").blue if @debugging

    self
  end

  def finish!
    @data[:appendix].gsub!(/appendix/i, "")&.strip! if @data[:appendix].present?
  end

  private

  def determine_available_from_context(captures: {})
    results = {}

    results[:title] = :present if context[:title] && !@data[:title].present? &&
      context_expected.include?(:title)

    if context[:section] && !@data[:section].present? &&
        (@data[:paragraph].present? || @data[:subpart].present?) &&
        (context_expected.include?(:section) ||
        context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("section"))
      results[:section] = :present
    elsif context[:appendix] && !@data[:section].present? &&
        (@data[:paragraph].present? || @data[:subpart].present?) &&
        (context_expected.include?(:section) ||
        context_expected.include?(:in_suffix) && captures[:suffix]&.downcase&.include?("section"))
      results[:appendix] = :present
    end

    %i[chapter subchapter part].each do |rank|
      if (reason = determine_rank_usability(rank: rank, captures: captures, existing: results, exclude_sub: (rank != :part)))
        results[rank] = reason
      end
    end

    puts "determine_available_from_context \"#{results}\" context_expected \"#{context_expected}\"" if @debugging
    results
  end

  def determine_rank_usability(rank:, captures:, existing:, exclude_sub: true)
    reason = nil

    if context[rank] && !@data[rank].present? # rank is available in the context, but not yet populated
      if (rank == :part) && (@data[:paragraph].present? || @data[:subpart].present? || (@data[:section].present? && !@data[:section]&.include?("."))) && context_expected.include?(:part)
        reason ||= :not_expecting_lower_rank_below_part
      end

      if @data[:paragraph].present? || @data[:subpart].present? || @data[:part].present?
        if ((rank == :chapter) && !@data[:section].present? && !existing.include?(:section) && !context_expected.include?(:section)) ||
            ((rank == :subchapter) && !data[:section].present? && !context_expected.include?(:section) && (!context_expected.include?(:chapter) && !existing.include?(:chapter)))
          reason ||= :not_expecting_lower_rank
        end
      end

      if context_expected.include?(:in_suffix) && (!exclude_sub || !captures[:suffix]&.downcase&.include?("sub#{rank}")) && captures[:suffix]&.downcase&.include?(rank.to_s)
        reason ||= if rank == :part && (section = captures[:section]).present? && section.include?(".") && !section.include?(context[:part])
          :potentially_misleading
        else
          :due_to_suffix
        end
      end
    end

    puts "adding #{rank} from context (#{reason})" if reason && @debugging
    reason
  end

  def decide_section_vs_part(expected: {})
    if !@data[:part] && @data[:section]
      if @options[:prefer_part] && !@data[:section]&.include?(".")
        unless expected[:appendix] && !@data[:appendix]
          repartition(:part, ".", :section, drop_divider: true)
        end
      elsif expected[:part]
        # take section if missing part & expecting it
        slide_left(:part, :section)
        slide_left(:part_end, :section_end)
      end
    end
  end
end
