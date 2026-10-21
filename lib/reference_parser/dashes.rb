# frozen_string_literal: true

class ReferenceParser::Dashes
  EM_DASH = "—"
  EN_DASH = "–"
  LOWBARM = "＿"
  UNDERSCORE = "_"

  DASHES = ["-", EM_DASH, EN_DASH]

  class << self
    def ascii(text)
      simplify(text, "-")
    end

    def complex?(text)
      text.include?(EM_DASH) || text.include?(EN_DASH)
    end

    def count(text)
      DASHES.inject(0) { |t, dash| t + text.count(dash) }
    end

    def permute(text, max_occurrences: 5)
      if count(text) < max_occurrences
        permute_dashes(text)
      else
        Set.new([text])
      end
    end

    def permute_dashes(text)
      remainders = (text.length > 1) ? permute(text[1..]) : [""]
      Set.new(
        if DASHES.include?(text[0])
          DASHES.map do |dash|
            remainders.collect { |r| dash + r }
          end.flatten
        else
          remainders.collect { |r| text[0] + r }
        end
      )
    end

    def simplify(text, replacement = nil)
      return text unless text.present?
      text = text.to_s unless text.is_a?(String)
      text&.gsub(EM_DASH, replacement || " - ")&.tr(EN_DASH, replacement || "-")
    end
  end

  ANY = /[-#{EN_DASH}#{EM_DASH}]/
end
