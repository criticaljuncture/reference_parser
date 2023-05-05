module ReferenceParser::HierarchyContainer
  attr_accessor :options, :debugging, :data, :order, :parent

  delegate :dig, :values_at, :except, :stringify_keys,
    :[], :"[]=",
    :merge, :merge!, :reverse_merge, :reverse_merge!,
    :slice, :delete,
    :inspect, :to_s,
    to: :@data

  def initialize(data = nil, debugging: false, options: {}, order: nil, parent: nil)
    @debugging = debugging
    @options = options
    @order = order || ReferenceParser::CaptureOrder.new
    @parent = parent
    @data = data || {}
    @potentially_misleading = []
  end

  def slide_left(left, right)
    @data[left] = @data.values_at(left, right).compact.join
    @data.delete(right)
    if @data[left]&.length == 0
      @data.delete(left)
    else
      order.track(left, right)
    end
  end

  def slide_right(left, right)
    @data[right] = @data.values_at(left, right).compact.join
    @data.delete(left)
    if @data[right]&.length == 0
      @data.delete(right)
    else
      order.track(left, right)
    end
  end

  def slide_likely_paragraph_right(left, right)
    # sections w/ multiple parentheticals currently (1/18/2022) only exist prior to a dash
    # ex: "275.202(a)(11)(G)-1", "1.431(c)(6)-1", "36.3121(l)(10)-1"
    section = @data[left]
    paragraph = @data[right]

    if section.present? && section.count("(") > 1
      slide_after_index = if (last_dash = section.rindex("-"))
        # dash, slide everything after the first paren after the dash
        section.chars.each_with_index.filter_map { |char, i| (char == "(" && i > last_dash) ? i : nil }.first
      else
        # no dash, slide everything after the first paren
        section.index("(")
      end

      if slide_after_index
        section, paragraph_in_section = [section.slice!(0, slide_after_index), section]
        @data[left] = section
        @data[right] = paragraph_in_section + (paragraph || "")
        order.track(left, right) unless paragraph
      end
    end
  end

  def repartition(left, pivot, right, drop_divider: false)
    left_value, pivot_value, right_value = @data.values_at(left, right).compact.join.partition(pivot)
    right_value = [pivot_value, right_value].compact.join unless drop_divider
    updated = false
    if left_value.length > 0
      @data[left] = left_value
      updated = true
    else
      @data.delete(left)
    end
    if right_value.length > 0
      @data[right] = right_value
      updated = true
    else
      @data.delete(right)
    end
    order.track(left, right) if updated
  end

  def drop_whitespace_and_italics(which)
    if @data[which].present?
      @data[which] = @data[which].gsub(/\s+/, "").gsub(/<\/?em>/, "")
    end
  end

  def to_h
    @data
  end

  def ==(other)
    if other.respond_to?(:data)
      @data == other.send(:data)
    else
      false
    end
  end

  def context_expected
    @context_expected ||= [options&.[](:context_expected)].flatten
  end

  private

  def context
    @context ||= options[:context] || {}
  end
end
