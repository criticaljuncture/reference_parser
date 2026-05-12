class ReferenceParser::Hints
  KNOWN_REFERENCES = {
    usc: [
      "15 USC 78l",
      "16 USC 742a"
    ]
  }.freeze

  DELIMITERS = {
    usc: " USC "
  }.freeze

  def self.sections_for(source, title)
    Array(KNOWN_REFERENCES[source])
      .filter_map { |reference| parse(reference, source: source) }
      .select { |entry| entry[:title] == title.to_s }
      .map { |entry| entry[:section] }
  end

  def self.parse(reference, source:)
    delimiter = DELIMITERS[source]
    return unless delimiter

    title, section = reference.to_s.split(delimiter, 2)
    return unless title.present? && section.present?

    {title: title, section: section}
  end
  private_class_method :parse
end
