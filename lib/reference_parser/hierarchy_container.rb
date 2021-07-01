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
