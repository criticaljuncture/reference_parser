class ReferenceParser::HierarchyCaptures
  LIST_DESIGNATORS = /,|;|or|and|&|through|to/ix

  LIST_EXAMPLES = /
    (?:<em>)?\s*Examples?\s*.                         # required example text
    (?:
      (?:<em>)?\s*(?:Examples?\s*)?                   # optional italics and or repeated example test
      \d+                                             # number
      (?:<\/em>)?                                     # close italics if needed
      (?:\s*through\s*|\s*,\s*(?:and\s*)?)?
    )+                                                # allow a list of examples
    (?:\s*in\s*)?                                     # in
    /ix

  UNITALICIZED_SECTION_SYMBOL = /(?<pre>\s*)<\/em>(?<symbol>\s*§\s*)<em>(?<post>\s*)/

  include ReferenceParser::HierarchyContainer

  attr_accessor :options, :repeated, :repeated_capture, :captured_characters

  ET_SEQ_COMMA_PLACEHOLDER = "__ET_SEQ_COMMA__"
  EM_SEMICOLON_PLACEHOLDER = "__EM_SEMICOLON__"

  def from_named_captures(named_captures)
    # save initial capture order
    @order = ReferenceParser::CaptureOrder.new(named_captures)
    @captured_characters = named_captures.values.sum { |value| value.to_s.length }

    # normalize captures & discard empty groups
    @data = named_captures.select { |k, v| v }.symbolize_keys

    # eject trailing period
    repartition(@data.keys.last, ".", :suffix_unlinked, from_end: true) if @data[@data.keys.last].to_s&.end_with?(".")

    # cleanup
    slide_right(:paragraph, :suffix) if only_whitespace?(:paragraph)
    if @data[:chapter].present? && @data[:sections].present? && @data[:chapter].to_s.strip.match?(/\A\d+\z/)
      chapter_item = "#{@data[:chapter_label]}#{@data[:chapter]}".strip
      and_joiner = " and "
      @data[:sections] = "#{chapter_item}#{and_joiner}#{@data[:sections]}"
      @captured_characters += and_joiner.length
      @data.delete(:chapter)
      @data.delete(:chapter_label)
    end
    if (handler = list_source_handler)
      handler.extract_publ_attribution_aside!(@data)
      handler.extract_as_amended_aside!(@data)
    end
    keep_as_sections_list = handler&.space_separated_section_list?(@data[:sections])
    slide_right(:sections, :section) if @data[:sections] && !@data[:section] && !(LIST_DESIGNATORS =~ @data[:sections]) && !keep_as_sections_list
    slide_left(:sections, :appendices) if @data[:appendices]
    restore_paragraph
    if list?(@data[:sections]) && list?(@data[:paragraphs])
      @data[:rolled_up_paragraphs] = true
      slide_left(:sections, :paragraphs)
    end

    if @data[:section_label]&.include?("§")
      if (match = UNITALICIZED_SECTION_SYMBOL.match(@data[:section_label]))
        @data[:section_label] = @data[:section_label].gsub(match[0], match[:pre] + "     " + match[:symbol] + "    " + match[:post])
      end
    end

    split_lists_into_individual_items(%i[prefixed_paragraphs parts subparts sections paragraphs])

    slide_left(:appendix_label, :appendix_label_middle)

    slide_left(:section, :part_string)

    if @data[:hierarchy_alias].present?
      if (alias_config = ReferenceParser::Cfr::HIERARCHY_ALIASES[@data[:hierarchy_alias].strip.tr(".", "").upcase])
        @data[:alias_hierarchies] = (alias_config[:hierarchies]&.dup || [])
        @data[:alias_hierarchies] << alias_config[:hierarchy].dup if alias_config[:hierarchy]
        puts Rainbow("from_named_captures using alias \"#{@data[:hierarchy_alias]}\" ").blue + Rainbow(@data).green if @debugging
      elsif @debugging
        puts Rainbow("from_named_captures no alias found for #{@data[:hierarchy_alias]}").yellow
      end
    end

    self
  end

  def build_hierarchy(index)
    ranks = %i[title chapter]
    ranks << :subchapter if expected[:subchapter]
    ranks.concat(%i[section prefixed_part part])
    ranks << :subtitle if expected[:subtitle]
    ranks.concat((!index || index == 0) ? %i[subpart prefixed_subpart] : %i[subpart]) if expected[:subpart]
    ranks << :part if expected[:part]
    ranks.concat(%i[paragraph prefixed_paragraph])
    ranks << :appendix if expected[:appendix]
    ReferenceParser::Hierarchy.new(@data.slice(*ranks), options: @options, debugging: @debugging)
  end

  def expected
    @expected ||= { # determine expected captures
      subtitle: @data[:subtitle_label].present?,
      subchapter: @data[:subchapter_label].present?,
      part: @data.values_at(*%i[part_label appendix_label]).detect(&:present?),
      subpart: @data.values_at(*%i[prefixed_subpart_label subpart_label]).detect(&:present?),
      section: @data[:section_label].present?,
      appendix: @data[:appendix_label].present?
    }
  end

  def processing_a_list
    (repeated.count > 1) || @data[:part_label]&.include?("parts")
  end

  def determine_repeated_capture
    @repeated_capture, @repeated = nil, nil

    to_consider = %i[prefixed_paragraph section subpart paragraph part].map { |rank| [:"#{rank}s", rank] }

    to_consider.each_with_index do |rank_keys, index|
      rank_values = @data.values_at(*rank_keys).flatten.select(&:present?)
      if !repeated || (!repeated.present? && rank_values.present?) ||
          (
            repeated.is_a?(Array) && (repeated.count == 1) &&
            rank_values.is_a?(Array) && ((rank_values&.count || 0) >= 2)
          )
        @repeated = rank_values
        @repeated_capture = rank_keys.last
      end
    end

    @repeated_capture, @repeated = :none, [""] unless repeated.present?

    # move repeat captures to normal if not selected (ie paragraph <= paragraphs)
    to_consider.each do |rank_keys|
      slide_left(*rank_keys.reverse) if repeated != rank_keys.last
    end

    order.repeated_capture = @repeated_capture
  end

  def loop_captures_for(what)
    result = ReferenceParser::HierarchyCaptures.new({
      repeated_capture => what # start with the repeated element
    }, options: @options, order: @order, debugging: @debugging, parent: self)

    # add remainder
    result.reverse_merge!(@data.except(:prefix, :suffix))

    result.prepare_loop_captures(processing_a_list: processing_a_list)
    result
  end

  def prepare_loop_captures(processing_a_list: false)
    restore_paragraph unless processing_a_list
  end

  def prefix_text_suffix(first_loop:, final_loop:)
    # reassemble capture text into prefix (link text) suffix

    loop_prefix_unlinked = first_loop ? parent[:prefix_unlinked] || "" : ""
    loop_prefix = first_loop ? parent[:prefix] || "" : ""
    loop_suffix = final_loop ? parent[:suffix] || "" : ""
    loop_suffix_unlinked = final_loop ? parent[:suffix_unlinked] || "" : ""

    text_from_captures = (!parent.processing_a_list || first_loop) ? order.first_loop_named_captures : [] # first loop/prefix
    text_from_captures << parent.repeated_capture
    text_from_captures.concat(order.last_loop_named_captures) if final_loop # last loop/suffix

    text = (loop_prefix || "") + slice(*(text_from_captures - %i[prefix_unlinked prefix suffix suffix_unlinked])).values.join + (loop_suffix || "")

    [loop_prefix_unlinked, text, loop_suffix_unlinked]
  end

  private

  LIST_ITEM_DIVIDERS_THAT_ARE_NOT_RANGE_DELIMITERS = /,|;|and|&|or|through/ixo

  CFR_SECTION_LIST_ITEM_DIVIDERS = /,|;|\band\b|&|\bor\b|through/ixo

  # dividers that should be kept with the subsequent item
  TRAILING_DIVIDERS = /and|&|or|to|through/ix

  ANY_DIVIDER = /(?<split>(?:\s*(?:#{LIST_ITEM_DIVIDERS_THAT_ARE_NOT_RANGE_DELIMITERS})\s*))/ix

  CFR_SECTION_LIST_DIVIDER = /
    (?<split>
      (?:\s*(?:#{CFR_SECTION_LIST_ITEM_DIVIDERS})\s*) |
      \s+(?<!to\s)(?<!through\s)(?=\d+\.\d+(?:\s*(?:[,;(]|introductory\s+text\b))?)
    )
  /ix

  # patterns to indicate if an entire value is composed of dividers (ie in the list ["item a", " and ", "item b"] the middle value should match to be merged)
  ALL_DIVIDERS = /\A(?<split>(?:\s+|#{LIST_ITEM_DIVIDERS_THAT_ARE_NOT_RANGE_DELIMITERS}|<\/?em>)+)\z/ixo
  ALL_DIVIDERS_IN_PARAGRAPH = /\A(?<split>(\s+|#{LIST_ITEM_DIVIDERS_THAT_ARE_NOT_RANGE_DELIMITERS}|#{LIST_EXAMPLES})+)\z/ixo # skipping "examples" for the moment

  def split_lists_into_individual_items(keys)
    handler = list_source_handler
    keys.each do |key|
      original = @data[key]
      next unless original.present?
      clean = @data[key].dup
      sections_handler = (key == :sections) ? handler : nil

      consumed_keys = []
      if key == :sections && ((clean&.include?("(") && @data[:paragraphs]&.include?("(")) || (clean&.end_with?("-") || @data[:sections]&.start_with?("-")))
        clean << @data[:paragraphs] if @data[:paragraphs].present?
        consumed_keys << :paragraphs
      end
      if key == :paragraphs && (clean&.start_with?("-") || any_end_with?([:sections, :section], "-"))
        clean = [@data[:section], @data[:sections], clean].compact.join
        consumed_keys.concat([:section, :sections])
      end

      if key == :sections && clean&.match?(/\bet\s*seq\.\s*,\s*<\/em>/i)
        clean = clean.gsub(/(\bet\s*seq)\.(\s*,)(\s*<\/em>)/i) { "#{Regexp.last_match(1)}.#{ET_SEQ_COMMA_PLACEHOLDER}#{Regexp.last_match(3)}" }
      end

      if key == :sections && clean&.include?("<em>")
        clean = clean.gsub(/(<em>[^<]*);([^<]*<\/em>)/i) { "#{Regexp.last_match(1)}#{EM_SEMICOLON_PLACEHOLDER}#{Regexp.last_match(2)}" }
      end

      if sections_handler
        clean, delta = sections_handler.normalize_sections_list_text(clean)
        @captured_characters += delta
      end

      cfr_section_list = key == :sections && (@options[:source].nil? || @options[:source] == :cfr) &&
        clean&.match?(/\b(?:introductory\s+text|notes?\s+to)\b/i)

      split = sections_handler&.split_sections_list(clean) ||
        if cfr_section_list
          clean&.split(CFR_SECTION_LIST_DIVIDER)&.select { |s| s.length > 0 }
        else
          clean&.split(ANY_DIVIDER)&.select { |s| s.length > 0 }
        end
      if sections_handler
        split, delta = sections_handler.post_process_section_list_items(split)
        @captured_characters += delta
      end
      if @options[:source] && @options[:source] != :cfr
        split = split.flat_map do |s|
          parts = s.split(/(?<=\s)/, 2)
          split_spaced_item?(s, parts, handler) ? parts : [s]
        end
      end

      if split.present?
        all_dividers = (key == :paragraphs) ? ALL_DIVIDERS_IN_PARAGRAPH : ALL_DIVIDERS
        x = 0
        while x < split.length
          puts Rainbow("split x #{x} split #{split} (#{key})").blue if @debugging
          if all_dividers.match?(split[x]) || # only list cruft
              (collapsing_examples = split[x - 1].include?("example") && !split[x - 1].include?("paragraph")) # "examples 1, 2, 3, 4, 5, and 6 in paragraph (j) of this section"
            if (split[x] =~ TRAILING_DIVIDERS) && (x < (split.length - 1)) && !collapsing_examples
              split[x + 1] = split[x] + split[x + 1]
              split.delete_at(x)
            elsif x > 0
              split[x - 1] = split[x - 1] + split[x]
              split.delete_at(x)
            elsif x < split.length - 1
              split[x] = split[x] + split[x + 1]
              split.delete_at(x + 1)
            else
              x += 1
            end
          else
            x += 1
          end
        end
        if split.count > 1
          @data[key] = split
          consumed_keys.each { |consumed_key| @data.delete(consumed_key) }
        elsif clean != original
          @data[key] = split&.first || clean
        end
      end

      if key == :sections && @data[key].present?
        @data[key] = if @data[key].is_a?(Array)
          @data[key].map { |item| item.gsub(ET_SEQ_COMMA_PLACEHOLDER, ",").gsub(EM_SEMICOLON_PLACEHOLDER, ";") }
        else
          @data[key].gsub(ET_SEQ_COMMA_PLACEHOLDER, ",").gsub(EM_SEMICOLON_PLACEHOLDER, ";")
        end
      end

      if @debugging
        puts Rainbow("split_lists_into_individual_items [").blue + (@data[key] || []).map { |i| Rainbow(i.to_s).green }.map { |i| Rainbow('"').blue + i + Rainbow('"').blue }.join(Rainbow(", ").blue) + Rainbow("] <= \"#{original}\"").blue if @debugging && original != @data[key]
      end
    end
  end

  def list_source_handler
    case @options[:source]
    when :usc then ReferenceParser::Usc
    end
  end

  # modifiers that belong with the preceding number ("1234 et seq.", "1234 note")
  SPACED_ITEM_MODIFIER = /\A(?:<em>\s*)?(?:,\s*)?(?:et\s*seq|as\s+amended|notes?|preceding\s+notes?|\(\s*notes?\s*\)|introductory\s+text)\b/i

  def split_spaced_item?(item, parts, handler)
    return false if /\Achapter\s+\d+\z/i.match?(item)
    return false unless parts.length == 2 && parts.all?(&:present?)
    return false if handler&.preserve_spaced_section_parts?(parts.first, parts.last)
    return false if parts.last.start_with?("(") || parts.last.match?(SPACED_ITEM_MODIFIER) || parts.last.match?(/\Ato\s+/i)
    !parts.first.match?(/\A#{ReferenceParser::Cfr::PART_APPENDIX_LABEL}\.?\s*\z/io)
  end

  def list?(capture)
    LIST_DESIGNATORS =~ capture
  end

  def only_whitespace?(capture)
    @data[:capture] =~ /\A\s*\Z/
  end

  def restore_paragraph
    # sections aren't expected to have parentheticals w/out a dashed suffix
    if @data[:section]&.include?("(") && !@data[:section]&.include?("-")
      paragraph_key = @data[:paragraphs].present? ? :paragraphs : :paragraph
      repartition(:section, "(", paragraph_key)
    end
  end

  private

  def any_end_with?(names, what)
    names.each do |name|
      if @data[name]&.respond_to?(:end_with?)
        return true if @data[name].end_with?(what)
      elsif @data[name]&.respond_to?(:last)
        return true if @data[name].last&.end_with?(what)
      end
    end
    nil
  end
end
