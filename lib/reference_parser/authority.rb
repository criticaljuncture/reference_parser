class ReferenceParser::Authority < ReferenceParser::Base
  include ReferenceParser::Lists

  # EO / Proclamation style numbers: "12674" or "12,674"
  COMMA_NUMBER = /(?:[1-9][0-9]{3,}|[1-9][0-9]{0,2},[0-9]{3})/
  LIST_CONJUNCTION = /(?:and|or)/i

  # "1, 2, and 3" / "1 or 2" (space required after comma)
  COMMA_AND_OR_DIVIDER = /\s*(?:,\s+|\s+#{LIST_CONJUNCTION}\s+)\s*/i

  # Pub. L. / Reorg. Plans: allows ";" and optional "and"/"or" after separators
  SEMICOLON_COMMA_AND_OR_DIVIDER = /\s*(?:[;,]\s*(?:#{LIST_CONJUNCTION}\s+)?|\s+#{LIST_CONJUNCTION}\s+)\s*/i

  def url(citation, url_options = {})
    "#"
  end

  def clean_up_named_captures(captures, options: {})
    return unless captures[:month].present?

    # full dates require a valid calendar day; year-only (optional_date_pattern) does not
    self.class.clean_up_date_captures(captures, required: true)
  end

  def self.slugs
    subclasses.map { |klass| klass.allocate.slug }.sort
  end

  def self.month_names_pattern
    @month_names_pattern ||= begin
      names = Date::MONTHNAMES.compact.map { |m| [m.length, Regexp.escape(m)] }
      abbrs = Date::ABBR_MONTHNAMES.compact.map { |a| [a.length, "#{Regexp.escape(a)}\\.?"] }
      (names + abbrs).sort_by { |(len, _)| -len }.map(&:last).uniq.join("|")
    end
  end

  # "June 25, 1982"
  def self.date_pattern
    /(?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*(?<year>[0-9]{4})/ix
  end

  # "June 25, 1982" or "1982"
  def self.optional_date_pattern
    /(?:(?<month>#{month_names_pattern})\s+(?<day>[0-9]{1,2}),\s*)?(?<year>[0-9]{4})/ix
  end

  def self.clean_up_date_captures(captures, required: false)
    unless captures[:date]
      month = month_index(captures[:month])
      year = captures[:year].to_i
      day = captures[:day].to_i
      if month && Date.valid_date?(year, month, day)
        captures[:date] = format("%04d-%02d-%02d", year, month, day)
      elsif required
        captures.clear
        return
      end
    end
    captures.delete(:month)
    captures.delete(:day)
    captures.delete(:year)
  end

  def self.month_index(month)
    month = month&.delete_suffix(".")
    Date::MONTHNAMES.find_index { it&.casecmp?(month) } || Date::ABBR_MONTHNAMES.find_index { it&.casecmp?(month) }
  end
  private_class_method :month_index
end
