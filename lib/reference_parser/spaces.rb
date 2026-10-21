# frozen_string_literal: true

class ReferenceParser::Spaces
  THIN_SPACE = " "
  EM_SPACE = " "
  EN_SPACE = " "
  FULLWIDTH_SPACE = "　"
  NON_BREAKING_SPACE = " "

  SPACES = [" ", EM_SPACE, EN_SPACE, FULLWIDTH_SPACE, THIN_SPACE]

  class << self
    def any?(text)
      text&.include?(" ") || complex?(text)
    end

    def none?(text)
      !any?(text)
    end

    def ascii(text)
      simplify(text, " ")
    end

    def complex?(text)
      SPACES.detect { |space| text&.include?(space) }
    end

    def simplify(text, replacement = nil)
      return text unless text.present?
      text = text.to_s unless text.is_a?(String)
      text = text&.tr(THIN_SPACE, replacement || " ")
      text = text&.tr(EM_SPACE, replacement || " ")
      text&.tr(EN_SPACE, replacement || " ")
    end
  end
end
