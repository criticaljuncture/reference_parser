class ReferenceParser::HierarchyCaptures
  LIST_DESIGNATORS = /,|or|and|through/ix

  LIST_EXAMPLES = /
    (<em>)?\s*Examples?\s*.                           # required example text
    (?:
      (?:<em>)?\s*(?:Examples?\s*)?                   # optional italics and or repeated example test
      \d+                                             # number
      (?:<\/em>)?                                     # close italics if needed
      (?:\s*through\s*|\s*,\s*(?:and\s*)?)?
    )+                                                # allow a list of examples
    (?:\s*in\s*)?                                     # in
    /ix

  include ReferenceParser::HierarchyContainer
  attr_accessor :options, :repeated, :repeated_capture

  def from_named_captures(named_captures)
    # normalize captures & discard empty groups
    @data = named_captures.select { |k, v| v }.symbolize_keys

    # cleanup
    slide_right(:paragraph, :suffix) if only_whitespace?(:paragraph)
    slide_right(:sections, :section) if @data[:sections] && !@data[:section] && !(LIST_DESIGNATORS =~ @data[:sections])
    restore_paragraph
    if list?(@data[:sections]) && list?(@data[:paragraphs])
      @data[:rolled_up_paragraphs] = true
      slide_left(:sections, :paragraphs)
    end

    split_lists_into_individual_items(%i[parts subparts sections paragraphs])

    slide_left(:section, :part_string)
    self
  end

  def build_hierarchy
    ranks = %i[title chapter]
    ranks << :subchapter if expected[:subchapter]
    ranks.concat(%i[section part])
    ranks << :subtitle if expected[:subtitle]
    ranks.concat(%i[subpart prefixed_subpart]) if expected[:subpart]
    ranks << :part if expected[:part]
    ranks.concat(%i[paragraph prefixed_paragraph])
    ReferenceParser::Hierarchy.new(@data.slice(*ranks), options: @options, debugging: @debugging)
  end

  def expected
    @expected ||= { # determine expected captures
      subtitle: @data[:subtitle_label].present?,
      subchapter: @data[:subchapter_label].present?,
      part: @data.values_at(*%i[part_label appendix_label]).detect(&:present?),
      subpart: @data.values_at(*%i[prefixed_subpart_label subpart_label]).detect(&:present?),
      section: @data[:section_label].present?
    }
  end

  def processing_a_list
    (repeated.count > 1) || @data[:part_label]&.include?("parts")
  end

  def determine_repeated_capture
    @repeated_capture, @repeated = nil, nil

    to_consider = %i[section subpart paragraph part].map { |rank| ["#{rank}s".to_sym, rank] }

    to_consider.each_with_index do |rank_keys, index|
      rank_values = @data.values_at(*rank_keys).flatten.select(&:present?)
      if !repeated || (!repeated.present? && rank_values.present?) ||
          (
            repeated.is_a?(Array) && ((repeated.count == 1) &&
            rank_values.is_a?(Array) && ((rank_values&.count || 0) >= 2))
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
  end

  def loop_captures_for(what)
    result = ReferenceParser::HierarchyCaptures.new({
      repeated_capture => what # start with the repeated element
    }, options: @options, debugging: @debugging)

    # add remainder
    result.reverse_merge!(@data.except(:prefix, :suffix))

    result.prepare_loop_captures(processing_a_list: processing_a_list)
    result
  end

  def prepare_loop_captures(processing_a_list: false)
    restore_paragraph unless processing_a_list
  end

  private

  def split_lists_into_individual_items(keys, simple: false)
    keys.each do |key|
      original = @data[key]
      next unless original.present?
      clean = @data[key].dup

      specific_all_dividers = nil
      specific_all_dividers = /(?<split>(,|\s+|and|or|through|#{LIST_EXAMPLES})+)/ixo if key == :paragraphs

      if simple
        # look-behind includes match in split (instead of discarding)
        clean[key] = clean[key]&.split(/(?<=(?:,|through|or|and))/)
      else
        # split on any list markers, then absorb into values prefering
        # commas to the left and connectors to the right
        any_divider = /(?<split>(?:\s*(?:,|and|or|through)\s*))/ix
        all_dividers = specific_all_dividers || /(?<split>(?:,|\s+|and|or|through|<\/?em>)+)/ix
        trailing_dividers = /and|or|through/ix
        split = clean&.split(any_divider)&.select { |s| s.length > 0 }
        if @data[:source] && @data[:source] != :cfr
          split = split.map do |s|
            resplit = s.split(/\s+/)
            resplit.count(&:present?) == 2 ? resplit : s
          end.flatten
        end
        if split.present?
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
          @data[key] = split if split.count > 1
        end
      end
      if @debugging
        puts "split_lists_into_individual_items \"#{original}\" into \"#{@data[key]}\"" if @debugging && original != @data[key]
      end
    end
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
end
