class ReferenceParser::Spaces
  THIN_SPACE = " "

  SPACES = [" ", THIN_SPACE]

  def self.ascii(text)
    simplify(text, " ")
  end

  def self.complex?(text)
    text.include?(THIN_SPACE)
  end

  def self.simplify(text, replacement = nil)
    return text unless text.present?
    text = text.to_s unless text.is_a?(String)
    text&.tr(THIN_SPACE, replacement || " ")
  end
end
