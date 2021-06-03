class ReferenceParser::Paragraph
  def self.guess_level(fragment)
    italic = fragment.include?("em>")
    clean_fragment = fragment.tr("(", "").tr(")", "").gsub(/<\/?em>/, "")
    case clean_fragment
    when /\d+/
      italic ? :italic_numbers : :numbers
    when /[ivx]+/ # reduced set for guess
      italic ? :italic_romans : :romans
    when /[A-Z]+/
      :upper_letters
    when /[a-z]+/
      :letters
    end
  end
end
