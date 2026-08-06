class ReferenceParser::Usc < ReferenceParser::Base
  include ReferenceParser::Lists

  SECTION_OF_TITLE_SECTIONS_LIST = /\d+[a-z]{0,5}(?:[-–—]\d+[a-z]{0,5})?(?:(?:\s*,\s*|\s+and\s+)\d+[a-z]{0,5}(?:[-–—]\d+[a-z]{0,5})?)*/

  OF_THE_USC_LABEL = /(?:of\s+the\s+)?#{ReferenceParser::Cfr::USC_LABEL}/

  # section 1506 of title 44, United States Code
  # secs. 8501-8508 of title 5, United States Code
  # secs. 803 and 805, title 26, United States Code
  replace(/(?<section_label>(?:sections?|secs?\.?)\s*)(?<section>#{SECTION_OF_TITLE_SECTIONS_LIST})(?<of_title_label>\s*(?:,\s*|\s+of\s+)title\s*)(?<title>\d+)(?<source_label>,?\s*#{OF_THE_USC_LABEL})/ixo, pattern_slug: :section_of_title_usc)
  replace(/chapter\s*(?<chapter>\d+)\s*of\s*title\s*(?<title>\d+),?\s*#{OF_THE_USC_LABEL}/ixo, pattern_slug: :chapter_of_title_usc)
  replace(/(?<irc_label>#{ReferenceParser::Cfr::IRC_LABEL})(?<section_label>\s*§\s*|\s*section\s*)(?<section>\d+[a-z]?)\b/ixo, pattern_slug: :usc_irc) # I.R.C. § 6212

  replace(/(?<title>\d+)\.?\s*#{ReferenceParser::Cfr::USC_LABEL},? Ch\.? (?<chapter>\d+)#{ReferenceParser::Cfr::TRAILING_MODIFIER}/o, pattern_slug: :usc_ch)

  def url(citation, url_options = {})
    return unless citation&.values_at(:title, :part)&.all?(&:present?)
    stripped = citation[:text]&.strip
    paragraph = citation.dig(:hierarchy, :paragraph).to_s
    if paragraph.match?(ReferenceParser::Cfr::LONE_PARAGRAPH) && stripped.blank?
      return
    end
    return if stripped&.match?(/\A\([a-z]{1,5}\)\s*;?\s*\z/i)
    return if stripped&.match?(/\A(?:and|or)\s+\([a-z]{1,5}\)\s*;?\s*\z/i)
    return if citation[:text]&.downcase&.include?("app") # !TODO pending appendix link format
    part = citation[:part].to_s.gsub(" ", "%20")
    "https://www.govinfo.gov/link/uscode/#{citation[:title]}/#{part}"
  end

  ALL_NUMERIC_RANGE_PATTERN = /\A(\d+)(-\d+)\z/

  def clean_up_named_captures(captures, options: {})
    if options[:pattern_slug] == :section_of_title_usc &&
        (section_list = captures[:section].to_s).match?(/\d+\s*(?:and|,)/i)
      captures[:sections] = section_list
      captures.delete(:section)
    end

    if (sections = captures.delete(:sections)).present?
      title = captures[:title]
      section_strings, dividers = split_list_parts(sections, divider: /\s+and\s+|,\s*/i)
      final = section_strings.length - 1
      return section_strings.map.with_index do |section, index|
        clean_up_named_captures(
          captures.merge(
            section: section,
            title: title,
            text: section,
            prefix: (index.zero? ? captures[:section_label] : nil),
            suffix: dividers[index] || ((index == final) ? captures.values_at(:of_title_label, :title, :source_label).join.presence : nil)
          ).compact,
          options: options
        )
      end
    end

    puts Rainbow("ReferenceParser::Usc#clean_up_named_captures ").dark.blue + Rainbow(captures.to_s).blue if @debugging
    captures.reverse_merge!(captures[:href_hierarchy] || captures[:hierarchy]) if captures[:href_hierarchy].present? || captures[:hierarchy].present?
    normalize_usc_appendix_hierarchy!(captures)
    if (hierarchy_appendix = captures[:hierarchy]&.[](:appendix)).present?
      captures[:appendix] = hierarchy_appendix
    end
    captures.delete(:part_appendix_label)
    captures.delete(:title_appendix_label)
    captures[:title] = "26" if !captures[:title] && captures[:irc_label].present?
    captures[:part] = captures[:section] if !captures[:part] && captures[:section]
    if options[:pattern_slug] == :section_of_title_usc
      captures.delete(:section) if captures[:part].present?
      captures.delete(:section_label)
      captures.delete(:of_title_label)
      captures.delete(:source_label)
    end
    captures[:part] = captures[:chapter] + "01" if !captures[:part] && captures[:chapter]
    captures[:part] = captures[:part].partition("(").first if captures[:part]&.include?("(")
    if (sublocators = captures[:sublocators]).present? && captures[:text]&.include?(sublocators)
      strip_attached_sublocators = captures.delete(:strip_attached_sublocators)
      attached = sublocators_attached_to_section?(captures, sublocators)
      strip_sublocators = if captures[:text].include?("§") || sublocators.count("(") > 1
        false
      elsif strip_attached_sublocators && (attached || trailing_alpha_sublocator?(captures, sublocators))
        captures[:text] =~ /#{Regexp.escape(sublocators)}\s*,\s*/
      elsif !attached && trailing_alpha_sublocator?(captures, sublocators)
        true
      elsif !attached && /\d+\.?\s*#{ReferenceParser::Cfr::USC_LABEL}/io.match?(captures[:text])
        captures[:text] =~ /#{Regexp.escape(sublocators)}\s*,\s*/
      else
        captures[:text] =~ /\A\s*(?:and|or)\s+\d+#{Regexp.escape(sublocators)}\s*\z/i
      end
      if strip_sublocators
        captures[:text] = captures[:text].sub(sublocators, "")
        trailing_comma = ""
        if captures[:text].end_with?(", ")
          captures[:text] = captures[:text].delete_suffix(", ")
          trailing_comma = ", "
        end
        push_to_suffix!(captures, "#{sublocators}#{trailing_comma}")
      end
    end
    if (paragraph = captures[:hierarchy]&.[](:paragraph)).present? &&
        captures[:text]&.match?(/\s+#{Regexp.escape(paragraph)}\z/) &&
        /\d+\.?\s*#{ReferenceParser::Cfr::USC_LABEL}/io.match?(captures[:text])
      captures[:text] = captures[:text].sub(/\s+#{Regexp.escape(paragraph)}\z/, "").strip
      push_to_suffix!(captures, paragraph, appended: " #{paragraph}")
    end
    if captures[:text]&.match?(/\d+\.?\s*#{ReferenceParser::Cfr::USC_LABEL}.+\s+notes?\b\z/io)
      note_match = captures[:text].match(/\s+(notes?)\b\z/i)
      captures[:text] = captures[:text].sub(/\s+notes?\b\z/i, "").strip
      captures[:suffix] = (captures[:suffix] || "") + " #{note_match[1]}"
    end
    if (match = ALL_NUMERIC_RANGE_PATTERN.match(captures[:part]))
      range_end = match[2].delete_prefix("-")
      if ReferenceParser::Guesses.abbreviated_numeric_range_end?(match[1], range_end)
        captures[:part] = match[1]
        if captures[:text].end_with?(match[2])
          captures[:text] = captures[:text].delete_suffix(match[2])
          captures[:suffix] = (captures[:suffix] || "") + match[2]
        end
      end
    elsif (section_end = captures[:section_end]).present? && captures[:part]&.match?(/\A\d+[a-z]{1,5}\z/i) && section_end.match?(/\A[a-z]{1,5}\z/i)
      range_suffix = "-#{section_end}"
      part_and_range = "#{captures[:part]}#{range_suffix}"
      if (match = captures[:text]&.match(/#{Regexp.escape(part_and_range)}(?<trailing>\s*,\s*)?/))
        captures[:text] = captures[:text].sub(/#{Regexp.escape(part_and_range)}(?<trailing>\s*,\s*)?/, captures[:part])
        captures[:suffix] = (captures[:suffix] || "") + range_suffix + (match[:trailing] || "")
      end
    end

    if captures[:part]&.match?(/\Aapp\.?\z/i)
      captures[:part] = "app"
      if captures[:suffix] == "."
        captures[:text] = "#{captures[:text]}." if captures[:text].present? && !captures[:text].end_with?(".")
        captures.delete(:suffix)
      end
    end

    captures[:part] = nil if ReferenceParser::Dashes::DASHES.include?(captures[:part])
    apply_usc_authority!(captures, options: options)
    strip_trailing_uppercase_artifacts_from_hierarchy!(captures)
    strip_non_identifying_modifiers!(captures)
    relocate_garbled_section_artifact!(captures)

    if captures[:authority].blank? && captures[:chapter].present? && captures[:part] == "#{captures[:chapter]}01"
      captures[:authority] = {section: captures[:chapter]}
    end

    apply_section_part_hints!(captures)
    relocate_unbalanced_closing_paren!(captures)
    finalize_authority_citation_fields!(captures) if options[:include_unlinked]

    return :skip if captures[:section].blank? && captures[:part].blank? && captures[:appendix].blank?

    captures
  end

  def depends_on_parser
    :cfr
  end

  def slug
    :usc
  end

  def handles_lists
    true
  end

  # "31301 et seq. 3302" or "31301, et seq., and 31502"
  ET_SEQ_SECTION_BREAK = /(\bet\s*seq)\.?(?:\s*<\/em>)?(?:\s*[,;])?(?:\s+|\s*,\s*(?:and\s+)?)(?=\d)/i
  APPENDIX_LABEL = /(?:App\.?|Appendix)/i

  SECTION_ASIDE_MODIFIER = /
    (?:
      [\s,]*as\s+amended |
      \s*\((?:\s*Repealed|\s*for\s)[^)]*\)? |
      \s*Ch(?:ap(?:ter)?|\.)?\.?\s*\d+\s+Sections? |
      [\s,;]+\d+[a-z]+\d+
    )[\s,;.]*\z
  /ixo

  def self.normalize_section_id(section)
    section.sub(SECTION_ASIDE_MODIFIER, "").strip
  end

  def self.finalize_section_id(section)
    section.sub(/\A(\d+(?:\.\d+)?[a-z]{0,5})\.\z/i, '\1')
  end

  def self.space_separated_section_list?(sections)
    s = sections.to_s
    s.match?(/\d\s+\d/) || s.match?(/\d[a-z]{0,5}\.\s+\d/i)
  end

  def self.extract_subchapters_aside!(data)
    return unless data[:sections].present?

    aside = data[:sections].match(ReferenceParser::Cfr::SUBCHAPTERS_OF_CHAPTER_ASIDE)
    return unless aside

    chapter = aside[0][/\d+\z/]
    replacement = ", #{chapter}"
    data[:subchapters_aside_text] = aside[0].sub(/\d+\z/, "")
    data[:sections_before_subchapters_aside] =
      data[:sections][0...aside.begin(0)].scan(/\d+(?:\.\d+)?(?:[a-z]{1,5})?/i).length
    data[:subchapters_sections_delta] = replacement.length - aside[0].length
    data[:sections] = data[:sections].sub(aside[0], replacement)
  end

  def self.embedded_publ_citations(aside_text)
    citations = []
    cursor = 0
    aside_text.to_s.scan(/#{ReferenceParser::Cfr::PL_LABEL}\d+[-–]\d+/io) do |label|
      label_begin = Regexp.last_match.begin(0)
      next unless (match = label.match(/(\d+)[-–](\d+)/))
      citation = {
        congress: match[1].to_i,
        law: match[2],
        text: label,
        source: :publ
      }
      if (joining_text = aside_text[cursor...label_begin]).present?
        citation[:prefix] = joining_text
      end
      citations << citation
      cursor = label_begin + label.length
    end
    citations
  end

  def self.joining_text_before(aside_text, target, preceding)
    target_begin = aside_text.rindex(target.to_s) or return
    consumed = if preceding && (index = aside_text.rindex(preceding[:text].to_s))
      index + preceding[:text].to_s.length
    else
      0
    end
    aside_text[consumed...target_begin].presence
  end

  def self.trailing_text_after(aside_text, target)
    target_end = aside_text.rindex(target.to_s) or return
    aside_text[(target_end + target.to_s.length)..].presence
  end

  def self.extract_publ_attribution_aside!(data)
    return unless data[:sections].present?

    publ_aside = data[:sections].match(ReferenceParser::Cfr::PUBL_ATTRIBUTION_ASIDE)
    return unless publ_aside

    data[:embedded_public_laws] = embedded_publ_citations(publ_aside[0])
    if (stat = ReferenceParser::Stat.embedded_from_comma_aside(publ_aside[0]))
      after_aside = data[:sections][publ_aside.end(0)..]
      if after_aside.blank? || !after_aside.match?(/\A\s*,\s*\d/)
        data[:embedded_stats] = [stat.merge(
          prefix: joining_text_before(publ_aside[0], stat[:text], data[:embedded_public_laws]&.last),
          suffix: trailing_text_after(publ_aside[0], stat[:text])
        ).compact]
      end
    end
    if data[:embedded_stats].blank? && (last_publ = data[:embedded_public_laws]&.last)
      last_publ[:suffix] = trailing_text_after(publ_aside[0], last_publ[:text])
    end
    before = data[:sections][0...publ_aside.begin(0)]
    after = data[:sections][publ_aside.end(0)..].to_s

    if before.match?(/[,;]\s*\z/) && (seam = after.match(/\A\s*[,;]\s*/))
      after = after[seam.end(0)..].to_s
      if (last_publ = data[:embedded_public_laws]&.last)
        last_publ[:suffix] = "#{last_publ[:suffix]}#{seam[0]}"
      end
    end

    data[:sections_before_publ_aside] = before.scan(/\d+(?:\.\d+)?(?:[a-z]{1,5})?/i).length
    data[:sections] = "#{before}#{after}"
  end

  PROTECTED_SPAN_PREFIX = "~SPAN"

  def self.protect_span(spans, text, divider: false)
    token = "#{PROTECTED_SPAN_PREFIX}#{spans.length}~"
    spans[token] = {text: text, divider: divider}
    divider ? "#{token}," : token
  end

  def self.normalize_sections_list_text(clean)
    spans = {}
    clean = clean.gsub(/(\d[a-z]{0,5})(\.\s+)(?=\d)/i) { "#{$1}#{protect_span(spans, $2, divider: true)}" }
    clean = clean.gsub(/(\d+[a-z]?)(\s+and\s+)(?=notes?\b)/i) { "#{$1}#{protect_span(spans, $2, divider: true)}" }
    clean = clean.gsub(ReferenceParser::Cfr::CHAP_N_SECTION_ASIDE) { protect_span(spans, $&, divider: true) }
    clean = clean.gsub(/(\(\s*notes?)(\s+and\s+)(?=\d)/i) { "#{$1}#{protect_span(spans, $2, divider: true)}" }
    [ReferenceParser::Cfr::EXPLANATORY_PARENTHETICAL,
      ReferenceParser::Cfr::REPEALED_PARENTHETICAL].each do |pattern|
      clean = clean.gsub(pattern) { protect_span(spans, $&) }
    end
    [clean, spans]
  end

  def self.split_sections_list(clean)
    return unless clean.match?(/,\s*(?:<em>\s*)?et\s*seq/i)

    parts = clean.split(/((?:;\s*(?:and\s+)?)|,\s*)(?=\d)/i)
    items = []
    idx = 0
    while idx < parts.length
      chunk = parts[idx].to_s
      if idx + 1 < parts.length && parts[idx + 1].match?(/\A(?:;\s*(?:and\s+)?|,\s*)\z/i)
        chunk += parts[idx + 1]
        idx += 2
      else
        idx += 1
      end
      items << chunk if chunk.length > 0
    end
    items
  end

  def self.post_process_section_list_items(items)
    items.flat_map do |item|
      if (match = item.match(ET_SEQ_SECTION_BREAK))
        [item[0...match.end(0)], item[match.end(0)..]]
      else
        [item]
      end
    end
  end

  def self.preserve_spaced_section_parts?(left, right)
    left&.match?(/\d\s*\z/) && right&.match?(/\A[a-z]{1,5}\z/i)
  end

  private

  NON_IDENTIFYING_MODIFIERS = /
    (?:[\s,]*as\s*amended | \s*\((?:Repealed|for\s)[^)]*\) | \s*Ch(?:ap(?:ter)?|\.)?\.?\s*\d+\s+Sections? | \.)\s*\z
  /ix

  def strip_non_identifying_modifiers!(captures)
    strip = lambda do |container, key|
      next unless container.is_a?(Hash)
      value = container[key].to_s
      container[key] = value.sub(NON_IDENTIFYING_MODIFIERS, "") if value.match?(NON_IDENTIFYING_MODIFIERS)
    end
    strip.call(captures, :section)
    strip.call(captures, :part)
    strip.call(captures[:hierarchy], :section)
    strip.call(captures[:authority], :section)
    strip.call(captures[:href_hierarchy], :part)

    # "3401 (note and 3402)" — the opening paren is left behind once the list splits
    unbalanced_paren = lambda do |container, key|
      next unless container.is_a?(Hash)
      value = container[key].to_s
      container[key] = value.sub(/\s*\(\s*/, " ").strip if value.count("(") > value.count(")")
    end
    unbalanced_paren.call(captures, :section)
    unbalanced_paren.call(captures, :part)
    unbalanced_paren.call(captures[:hierarchy], :section)
    unbalanced_paren.call(captures[:authority], :section)
    unbalanced_paren.call(captures[:href_hierarchy], :part)
  end

  GARBLED_SECTION_ARTIFACT = /(?<lead>[\s,;]+)(?<artifact>\d+[a-z]+\d+)(?<trail>[\s,;]*)\z/i

  def relocate_garbled_section_artifact!(captures)
    return unless (match = captures[:text]&.match(GARBLED_SECTION_ARTIFACT))

    captures[:text] = captures[:text][0...match.begin(0)]
    SECTION_ID_KEYS.each do |key|
      [captures, captures[:hierarchy], captures[:href_hierarchy], captures[:authority]].each do |container|
        next unless container.is_a?(Hash)
        container[key] = container[key].sub(GARBLED_SECTION_ARTIFACT, "") if container[key].is_a?(String)
      end
    end
    push_to_suffix!(captures, match[0])
  end

  def strip_trailing_uppercase_artifacts_from_hierarchy!(captures)
    artifact = captures[:text].to_s[ReferenceParser::Cfr::TRAILING_UPPERCASE_ARTIFACT_ASIDE, 0]
    return unless artifact

    strip = lambda do |container, key|
      value = container[key].to_s
      container[key] = value.delete_suffix(artifact) if value.end_with?(artifact)
    end
    strip.call(captures, :section)
    strip.call(captures, :part)
    strip.call(captures[:hierarchy], :section) if captures[:hierarchy]
    strip.call(captures[:authority], :section) if captures[:authority]&.[](:section).present?
    strip.call(captures[:href_hierarchy], :part) if captures[:href_hierarchy]&.[](:part).present?
  end

  # "15 U.S.C. 78o-4(b)" — trailing single-level paragraph following an alpha-suffixed section
  def trailing_alpha_sublocator?(captures, sublocators)
    captures[:text].end_with?(sublocators) &&
      sublocators.match?(ReferenceParser::Cfr::LONE_PARAGRAPH) &&
      captures[:hierarchy]&.[](:section).to_s.match?(/[a-z<\/]/i) &&
      !captures[:text].match?(/[-–—]\s*#{Regexp.escape(sublocators)}\z/)
  end

  def push_to_suffix!(captures, fragment, appended: fragment)
    captures[:suffix] = if captures[:suffix].present?
      "#{fragment}#{captures[:suffix]}"
    else
      appended
    end
  end

  def sublocators_attached_to_section?(captures, sublocators)
    text = ReferenceParser::Dashes.ascii(captures[:text].to_s)
    [captures[:part], captures[:hierarchy]&.[](:section)].compact.any? do |id|
      text.include?("#{ReferenceParser::Dashes.ascii(id.to_s)}#{sublocators}")
    end
  end

  def appendix_citation?(captures)
    hierarchy = captures[:hierarchy] || captures
    return true if captures[:part_appendix_label].present? || captures[:title_appendix_label].present?
    return true if hierarchy[:appendix].present?
    section = hierarchy[:section].to_s
    return true if section.match?(/\A#{APPENDIX_LABEL}\z/o)
    return true if section.match?(/\A#{APPENDIX_LABEL}\s+\S+/o)

    text = [captures[:prefix], captures[:text]].compact.join
    text.match?(/\bU\.?S\.?C\.?\s+#{APPENDIX_LABEL}\s+\d/o) || text.match?(/\bApp\.?\s+U\.?S\.?C/i)
  end

  def normalize_usc_appendix_hierarchy!(captures)
    hierarchy = captures[:hierarchy]
    return unless hierarchy.present?

    if (match = hierarchy[:section].to_s.match(/\A#{APPENDIX_LABEL}\s+(?<appendix>\S+.*)\z/o))
      hierarchy[:section] = match[:appendix]
      captures[:part_appendix_label] ||= "App"
    end

    return unless appendix_citation?(captures)

    if hierarchy[:appendix].to_s.strip.match?(/\AAppendix\.?\z/i)
      hierarchy[:section] = "Appendix"
      hierarchy.delete(:appendix)
      captures.delete(:appendix)
      if (href = captures[:href_hierarchy])
        href[:part] = "Appendix"
        href.delete(:appendix)
      end
      return
    end

    section = hierarchy[:section].to_s.strip
    return unless section.present?
    return if section.match?(/\A#{APPENDIX_LABEL}\b/o)

    if hierarchy[:section_end].present?
      section = "#{section}-#{hierarchy.delete(:section_end)}"
    end
    hierarchy[:appendix] = section
    hierarchy.delete(:section)
    captures[:appendix] = section

    if (href = captures[:href_hierarchy])
      relocated = href.delete(:part) || href.delete(:section) || section
      href.delete(:section_end)
      href[:appendix] = "Appendix%20#{relocated.to_s.gsub(" ", "%20")}"
    end
  end

  def apply_usc_authority!(captures, options: {})
    hierarchy = captures[:hierarchy]
    normalize_usc_et_seq_authority!(captures, hierarchy) if hierarchy.present?
    normalize_usc_preceding_note_authority!(captures, hierarchy) if hierarchy.present?
    return if captures[:authority].present?
    return unless hierarchy.present?

    authority = nil

    if (appendix = hierarchy[:appendix]).present? && appendix_citation?(captures)
      section = normalize_appendix_additional(appendix)
      section = "#{section}#{hierarchy[:paragraph]}" if hierarchy[:paragraph].present?
      authority = {
        title: hierarchy[:title],
        grouping: "Appendix",
        section: section
      }
    elsif (section = hierarchy[:section])
      if hierarchy[:paragraph].present?
        authority = {section: "#{section.strip}#{hierarchy[:paragraph]}"}
      elsif hierarchy[:section_end].present?
        alpha_suffix_range = ReferenceParser::Guesses.seems_like_an_alpha_suffix_range?([section, hierarchy[:section_end]])
        if !alpha_suffix_range || options[:include_unlinked]
          authority = {section: "#{section}-#{hierarchy[:section_end]}"}
        end
      elsif (resolved = ReferenceParser::Guesses.authority_section_for_abbreviated_numeric_range(section, captures[:text]))
        authority = {section: resolved}
      elsif section.match?(/\AAppendix\.?\z/i)
        authority = {grouping: "Appendix", section: "Appendix"}
      elsif (appendix_section = appendix_label_additional(captures, hierarchy)).present?
        authority = {grouping: "Appendix", section: appendix_section}
      end
    end

    if authority.nil? && hierarchy[:section].present?
      if (match = captures[:trailing_modifier]&.match(ReferenceParser::Cfr::TRAILING_MODIFIER_UNLABELED))
        authority = {section: "#{hierarchy[:section]}#{match[0]}"}
      end
    end

    captures[:authority] = authority if authority.present?
  end

  def normalize_usc_et_seq_authority!(captures, hierarchy)
    section = hierarchy[:section].to_s
    authority_section = captures[:authority]&.[](:section).to_s
    source = [section, authority_section].find { |value| value.match?(/et\s*seq/i) }
    return unless source.present?

    match = source.match(/\A(.+?)(?:,\s*|\s+)(?:<em>\s*)?(?:,\s*)?(et\s*seq)(\.?)(?:\s*,)?(?:\s*<\/em>)?(?:\s*,\s*)?\z/i)
    return unless match

    base = match[1].strip.delete_suffix(",")
    et_seq = match[2]
    formatted = "#{base} #{et_seq}".strip
    if hierarchy[:appendix].present? && appendix_citation?(captures)
      hierarchy[:appendix] = formatted
      captures[:appendix] = formatted
      hierarchy.delete(:section)
      captures[:authority] = {
        title: hierarchy[:title],
        grouping: "Appendix",
        section: formatted
      }
    else
      hierarchy[:section] = base
      captures[:authority] = {section: formatted}
    end
    captures[:trailing_modifier] = ", #{et_seq}" if captures[:final_loop]
  end

  def normalize_usc_preceding_note_authority!(captures, hierarchy)
    return unless captures[:text]&.match?(/\b#{ReferenceParser::Cfr::PRECEDING_NOTE_LABEL}\b/io)
    return unless hierarchy[:appendix].present?

    appendix = hierarchy[:appendix].to_s.strip
    formatted = "#{appendix} preceding note"
    hierarchy[:appendix] = formatted
    captures[:appendix] = formatted
    hierarchy.delete(:section)
    captures[:authority] = {
      title: hierarchy[:title],
      grouping: "Appendix",
      section: formatted
    }
  end

  def appendix_label_additional(captures, hierarchy)
    if (appendix = hierarchy[:appendix]).present?
      return normalize_appendix_additional(appendix)
    end

    label = captures[:part_appendix_label].presence || captures[:title_appendix_label].presence
    return label.strip.delete_suffix(".") if label.present?

    section = hierarchy[:section].to_s.strip
    return "App" if section.match?(/\AApp\.?\z/i)

    nil
  end

  def normalize_appendix_additional(value)
    normalized = value.to_s.strip
    return nil if normalized.match?(/\AAppendix\.?\z/i)

    normalized.sub(/\AAppendix\s+/i, "")
  end

  def finalize_authority_citation_fields!(captures)
    hierarchy = captures[:hierarchy] || {}
    if hierarchy[:appendix].present? || captures[:appendix].present?
      captures.delete(:part)
      captures.delete(:section)
      return
    end

    section = hierarchy[:section].presence || captures[:part]
    return unless section.present?

    captures[:section] = section
    captures.delete(:part)
  end

  UNBALANCED_CLOSING_PAREN = /\)(?<trailing>\s*[,;]?\s*)\z/
  SECTION_ID_KEYS = %i[part section].freeze

  def relocate_unbalanced_closing_paren!(captures)
    text = captures[:text].to_s
    return unless text.count(")") > text.count("(")
    return unless (match = text.match(UNBALANCED_CLOSING_PAREN))

    captures[:text] = text[0...match.begin(0)]
    [captures, captures[:hierarchy], captures[:href_hierarchy], captures[:authority]].each do |container|
      next unless container.is_a?(Hash)
      SECTION_ID_KEYS.each do |key|
        container[key] = container[key].delete_suffix(")") if container[key].is_a?(String)
      end
    end
    push_to_suffix!(captures, ")#{match[:trailing]}")
  end

  def apply_section_part_hints!(captures)
    hierarchy = captures[:hierarchy] || {}
    section = hierarchy[:section].to_s
    paragraph = hierarchy[:paragraph].to_s
    hinted_section = resolve_hinted_section(title: captures[:title], section: section, paragraph: paragraph)
    return unless hinted_section

    captures[:part] = hinted_section
    if captures[:hierarchy]
      captures[:hierarchy][:section] = hinted_section
      captures[:hierarchy].delete(:paragraph)
    end
    if captures[:href_hierarchy]
      captures[:href_hierarchy][:part] = hinted_section
      captures[:href_hierarchy].delete(:sublocators)
    end
  end

  def resolve_hinted_section(title:, section:, paragraph:)
    hinted_sections = ReferenceParser::Hints.sections_for(:usc, title)
    return unless hinted_sections.present?

    return section if hinted_sections.include?(section)

    if (match = paragraph.match(/\A\(([a-z]{1,5})\)\z/i))
      candidate = "#{section}#{match[1]}"
      return candidate if hinted_sections.include?(candidate)
    end

    nil
  end
end
