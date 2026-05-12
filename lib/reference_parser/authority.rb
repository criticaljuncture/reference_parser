class ReferenceParser::Authority < ReferenceParser::Base
  def url(citation, url_options = {})
    "#"
  end

  def self.slugs
    ObjectSpace.each_object(Class).select { |klass| klass < self }.map { |klass| klass.allocate.slug }.sort
  end

  def self.month_names_pattern
    (Date::MONTHNAMES.compact.map { |m| [m.length, Regexp.escape(m)] } + Date::ABBR_MONTHNAMES.compact.map { |a| [a.length, "#{Regexp.escape(a)}\\.?"] }).sort_by { |(len, _)| -len }.map(&:last).uniq.join("|")
  end

  private

  def month_index(month)
    month = month&.delete_suffix(".")
    Date::MONTHNAMES.find_index { it&.casecmp?(month) } || Date::ABBR_MONTHNAMES.find_index { it&.casecmp?(month) }
  end
end
