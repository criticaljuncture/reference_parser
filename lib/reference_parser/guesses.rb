class ReferenceParser::Guesses
  def self.numbers_seem_like_a_range?(list)
    return unless (list&.compact&.count || 0) > 1
    numbers = to_numbers(list)
    ((list.compact.count == 2) && numbers_similarish?(numbers) && numbers_increasing(numbers)) ||
      ((list.compact.count == 1) && (numbers.max < 50))
  end

  def self.numbers_similarish?(list)
    numbers = to_numbers(list)
    numbers.all? { |n| n < 50 } ||
      ((numbers.max - numbers.min) < 50) ||
      (numbers.min > numbers.max * 0.5)
  end

  def self.numbers_increasing(list)
    list.sort == list
  end

  def self.seems_like_a_range?(items)
    numbers_seem_like_a_range?(items.map(&:to_i)) || seems_like_an_alpha_suffix_range?(items)
  end

  def self.seems_like_an_alpha_suffix_range?(items)
    return false unless items.length == 2

    first_match = items.first.to_s.match(/\A\d+([a-z]{1,5})\z/i)
    last = items.last.to_s
    first_match && last.match?(/\A[a-z]{1,5}\z/i) && last.downcase >= first_match[1].downcase
  end

  def self.to_numbers(numbers)
    numbers.reject { |item| item.respond_to?(:empty?) && item&.empty? }.map(&:to_i)
  end

  COMMON_WORDS = %w[a addresses administrative after all an any applicable applies apply are as at awards be burn but by carried contains copies designed debarred declared do each ensuring equals even except expressed failure freedom from general has have if in ineligible is it liquid may need no on privacy provide pursuant receive rounded rr see shall sign special specifies subject success such suspended that this to under until value we whether which who will with within you].freeze
  DISCARDABLE_PREFIX = /\A\s*(?:and|&|or|through)\s*/i

  def self.abbreviated_numeric_range_end?(a, b)
    return false unless numeric?(a) && numeric?(b) # dealing with numbers
    return false unless a.length > b.length # range suffix is shorter

    b_complete = a[0...-b.length] + b
    return false unless b_complete.to_i > a.to_i # represents an increasing range

    (b[0] == a[-b.length]) || (b.length > 1)
  end

  def self.authority_section_for_abbreviated_numeric_range(section, text)
    items = section.to_s.split("-")
    return unless items.length == 2 && abbreviated_numeric_range_end?(items.first, items.last)

    (text.to_s.strip == items.first) ? items.first : section.to_s.strip
  end

  def self.unlikely_trailing_identifier?(identifier)
    COMMON_WORDS.include?(identifier.strip.downcase.gsub(DISCARDABLE_PREFIX, ""))
  end

  def self.numeric?(string)
    string.match?(/\A\d+\z/)
  end
  private_class_method :numeric?
end
