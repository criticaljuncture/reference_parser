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

  COMMON_WORDS = %w[a addresses administrative after all an any applicable applies apply are as at awards be burn but by carried contains copies designed debarred declared do each ensuring equals even except expressed failure freedom from general have if in ineligible is it liquid may need no on privacy provide pursuant receive rounded rr see shall sign special specifies subject success such suspended that this to under until value we whether which who will with within you].freeze
  DISCARDABLE_PREFIX = /\A\s*(?:and|or|through)\s*/i

  def self.unlikely_trailing_identifier?(identifier)
    COMMON_WORDS.include?(identifier.strip.downcase.gsub(DISCARDABLE_PREFIX, ""))
  end
end
