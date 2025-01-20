# track the order of named captures (both original and those created during processing) for use in reassembly of text
class ReferenceParser::CaptureOrder
  delegate :[], :"[]=", :index, :find_index, :count, :inspect, :to_s,
    to: :names

  attr_accessor :repeated_capture, :names

  def initialize(named_captures = nil)
    @names = prepare(named_captures) || []
    @repeated_capture = :none
  end

  def first_loop_named_captures
    names[0..(repeated_index - 1)] || []
  end

  def last_loop_named_captures
    names[(repeated_index + 1)..] || []
  end

  def repeated_index
    names.find_index(repeated_capture) || names.count
  end

  def prepare(named_captures)
    return unless named_captures
    results = named_captures.select { |k, v| v && !v&.empty? }.keys

    to_add = {}

    results.each do |key|
      if (singular = key.to_s).delete_suffix("s")
        singular = singular.to_sym
        to_add[singular] = key
      end
    end

    to_add.each do |singular, plural|
      if (index = results.index(plural))
        results.insert(index + 1, singular)
      end
    end

    results
  end

  def track(left, right)
    left_index = names.index(left)
    right_index = names.index(right)

    if left_index && !right_index
      insert_at = left_index + 1
      insert_at += 1 while (insert_at < names.count) && left.to_s.start_with?(names[insert_at].to_s)
      names.insert(insert_at, right)
    elsif !left_index && right_index
      insert_at = right_index
      insert_at -= 1 while (insert_at > 0) && names[insert_at - 1].to_s.start_with?(right.to_s)
      names.insert(insert_at, left)
    end
  end
end
