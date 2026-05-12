class ReferenceParser::Stat < ReferenceParser::Authority
  # United States Statutes at Large

  LIST_DIVIDER = /(?:\s*,\s*as\s+amended\s*,\s*|\s+as\s+amended\s*,\s*|\s*,\s*(?:and\s+)?|\s+and\s+)/i
  CHAPTER = /[0-9]{1,5}[a-z]?(?:-[0-9]{1,5}[a-z]?)?/
  CONTINUATION_CHAPTER = /
    (?:
      [0-9]{1,5}[a-z]?(?:-[0-9]{1,5}[a-z]?)?(?![0-9])
      |
      [0-9]{1,5}(?=[A-Z]-\d)
    )
  /x
  ET_SEQ = /\s+et\s+seq\.?/i
  # ", 118" or ", as amended, 66" — not ", 7 U.S.C.", ", 54 Stat.", or ", 49 CFR"
  NEXT_CITATION_AFTER_PAGE = /(?!\d+[A-Za-z]?\s*(?:(?:App\.\s*)?U\.?S\.?C|Stat\.?,?|C\.?F\.?R))/ix
  TRAILING_BOUNDARY = /(?:#{LIST_DIVIDER})#{NEXT_CITATION_AFTER_PAGE}#{CONTINUATION_CHAPTER}/ix
  # Stat page lists only (e.g. "394, secs. 394, 395"), not section ranges like "secs. 7-17".
  SECS_PAGE_LABEL = /[0-9]{1,5}[a-z]?/
  SECS_LABELED_PAGE = /,\s*secs\.\s+(?<secs_label>#{SECS_PAGE_LABEL})\s*,\s*(?<secs_continuation>#{CHAPTER})(?!\s*Stat\.?,?)/io
  VOLUME = /(?<volume>\d{1,3}[A-Za-z]?)/
  VOLUME_STAT_SEPARATOR = /(?:,\s*|\.\s*|\s+)/
  STAT_CORE = /#{VOLUME}#{VOLUME_STAT_SEPARATOR}Stat\.?,?\s+(?<chapter>#{CHAPTER})/io
  STAT_IN_PARENS = /\(\s*#{STAT_CORE}\s*\)/io
  TRAILING_STAT_PAREN = /\s*#{STAT_IN_PARENS}\s*\z/io
  # "Pub. L. 93-66, 87 Stat. 155" — Stat cite after a comma inside an aside
  STAT_AFTER_COMMA = /,\s*#{STAT_CORE}/io
  # "48 Stat., as amended, 1066" — volume cited before page list
  DEFERRED_CHAPTERS_PREFIX = /(?:,\s*as\s+amended\s*,\s*)?/i

  def self.embedded_from_parenthetical(text)
    embedded_citation(text, STAT_IN_PARENS) { |match| match[0][1..-2].strip }
  end

  def self.embedded_from_comma_aside(text)
    embedded_citation(text, STAT_AFTER_COMMA) { |match| match[0].sub(/\A,\s*/, "") }
  end

  # 68A Stat. 580 — Internal Revenue Code of 1954 volumes use a letter suffix
  replace(/#{VOLUME}#{VOLUME_STAT_SEPARATOR}Stat\.?,?\s*#{DEFERRED_CHAPTERS_PREFIX}(?<chapters>#{CHAPTER}(?:#{TRAILING_BOUNDARY})*)(?<secs_labeled_page>#{SECS_LABELED_PAGE})?(?<et_seq>#{ET_SEQ})?(?<trailing_sec>,\s*sec\.\s*[0-9]+)?/io, pattern_slug: :stat)

  def handles_lists
    true
  end

  def clean_up_named_captures(captures, options: {})
    if captures[:chapter].present? && captures[:chapters].blank?
      captures.delete(:chapters)
      return captures
    end

    raw = captures.delete(:chapters)
    secs_label = captures.delete(:secs_label)
    secs_continuation = captures.delete(:secs_continuation)
    captures.delete(:secs_labeled_page)
    if secs_label.present? && secs_continuation.present?
      last_page = raw[/([0-9]{1,5}[a-z]?)\s*\z/i, 1]
      raw = "#{raw}, #{secs_continuation}" if secs_label == last_page
    end
    raw = raw.gsub(/([0-9]{1,5}[a-z]?)\s*,\s*secs\.\s+\1\s*,\s*/io, '\1, ')
    trailing_sec = captures.delete(:trailing_sec)
    et_seq = captures.delete(:et_seq)
    chapter_strings, dividers = split_list_parts(raw, divider: LIST_DIVIDER, keep: ->(c) { c.match?(/\A#{CHAPTER}\z/o) })

    if et_seq.present?
      modifier = et_seq.strip.sub(/\.+\z/, "")
      chapter_strings[-1] = "#{chapter_strings.last} #{modifier}" if chapter_strings.last.present?
    end

    if chapter_strings.size <= 1
      captures[:chapter] = chapter_strings.first
      return captures
    end

    volume = captures[:volume]
    citations = build_list_citations("#{volume} Stat.", chapter_strings, dividers) do |chapter|
      {volume: volume, chapter: chapter}
    end
    citations.last[:suffix] = "#{citations.last[:suffix]}#{trailing_sec}" if trailing_sec.present?
    citations
  end

  def slug
    :stat
  end

  def self.embedded_citation(text, pattern)
    match = text.to_s.match(pattern)
    return unless match

    {
      volume: match[:volume],
      chapter: match[:chapter],
      text: yield(match),
      source: :stat
    }
  end
  private_class_method :embedded_citation
end
