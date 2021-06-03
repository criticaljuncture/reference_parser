class ReferenceParser::Guesses
  def self.numbers_seem_like_a_range?(numbers)
    (numbers.count == 2) && numbers.all?(&:nonzero?) && numbers_similarish(numbers)
  end

  def self.numbers_similarish(numbers)
    numbers.all? { |n| n < 50 } ||
      ((numbers.max - numbers.min) < 50) ||
      (numbers.min > numbers.max * 0.5)
  end
end
