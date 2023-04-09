class ReferenceParser::Dashes
  EM_DASH = "—"
  EN_DASH = "–"

  DASHES = ["-", EM_DASH, EN_DASH]

  def self.ascii(text)
    simplify(text, "-")
  end

  def self.complex?(text)
    text.include?(EM_DASH) || text.include?(EN_DASH)
  end

  def self.count(text)
    DASHES.inject(0) { |t, dash| t + text.count(dash) }
  end

  def self.permute(text, max_occurrences: 5)
    if count(text) < max_occurrences
      permute_dashes(text)
    else
      Set.new([text])
    end
  end

  def self.permute_dashes(text)
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

  def self.simplify(text, replacement = nil)
    return text unless text.present?
    text = text.to_s unless text.is_a?(String)
    text&.gsub(EM_DASH, replacement || " - ")&.tr(EN_DASH, replacement || "-")
  end

  ANY = /[-#{EN_DASH}#{EM_DASH}]/
end
