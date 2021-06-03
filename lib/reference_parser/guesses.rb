class ReferenceParser::Guesses
  def self.numbers_seem_like_a_range?(list)
    return unless (list&.compact&.count || 0) > 1
    numbers = to_numbers(list)
    ((list.compact.count == 2) && (numbers_similarish(numbers) && numbers_increasing(numbers))) ||
      ((list.compact.count == 1) && (numbers.max < 50))
  end

  def self.numbers_similarish(list)
    numbers = to_numbers(list)
    numbers.all? { |n| n < 50 } ||
      ((numbers.max - numbers.min) < 50) ||
      (numbers.min > numbers.max * 0.5)
  end

  def self.numbers_increasing(list)
    list.sort == list
  end

  def self.to_numbers(numbers)
    numbers.reject { |item| item.respond_to?(:empty?) && item&.empty? }.map(&:to_i)
  end
end
