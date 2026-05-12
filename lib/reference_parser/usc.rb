class ReferenceParser::Usc < ReferenceParser::Base
  include ReferenceParser::Lists

  SECTION_OF_TITLE_SECTIONS_LIST = /\d+[a-z]{0,5}(?:[-–—]\d+[a-z]{0,5})?(?:(?:\s*,\s*|\s+and\s+)\d+[a-z]{0,5}(?:[-–—]\d+[a-z]{0,5})?)*/

  OF_THE_USC_LABEL = /(?:of\s+the\s+)?#{ReferenceParser::Cfr::USC_LABEL}/

  # section 1506 of title 44, United States Code
  # secs. 8501-8508 of title 5, United States Code
  # secs. 803 and 805, title 26, United States Code
  replace(/(?:sections?|secs?\.?)\s*(?<section>#{SECTION_OF_TITLE_SECTIONS_LIST})\s*(?:,\s*|\s+of\s+)title\s*(?<title>\d+),?\s*#{OF_THE_USC_LABEL}/ixo, pattern_slug: :section_of_title_usc)
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
      section_strings, = split_list_parts(sections, divider: /\s+and\s+|,\s*/i)
      return section_strings.map.with_index do |section, index|
        clean_up_named_captures(
          captures.merge(
            section: section,
            title: title,
            text: section
          ),
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
    if options[:pattern_slug] == :section_of_title_usc && captures[:part].present?
      captures.delete(:section)
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

    if captures[:authority].blank? && captures[:chapter].present? && captures[:part] == "#{captures[:chapter]}01"
      captures[:authority] = {section: captures[:chapter]}
    end

    apply_section_part_hints!(captures)
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

  def self.space_separated_section_list?(sections)
    s = sections.to_s
    s.match?(/\d\s+\d/) || s.match?(/\d[a-z]{0,5}\.\s+\d/i)
  end

  def self.extract_as_amended_aside!(data)
    return unless data[:sections].present?

    aside = data[:sections].match(ReferenceParser::Cfr::AS_AMENDED_ASIDE)
    return unless aside

    data[:as_amended_aside_text] = aside[0]
    data[:sections_before_as_amended_aside] =
      data[:sections][0...aside.begin(0)].scan(/\d+(?:\.\d+)?(?:[a-z]{1,5})?/i).length
    data[:sections] = data[:sections].sub(aside[0], "")
  end

  def self.embedded_publ_citations(aside_text)
    citations = []
    aside_text.scan(/#{ReferenceParser::Cfr::PL_LABEL}\d+[-–]\d+/io) do |label|
      next unless (match = label.match(/(\d+)[-–](\d+)/))
      citations << {
        congress: match[1].to_i,
        law: match[2],
        text: label,
        source: :publ
      }
    end
    citations
  end

  def self.extract_publ_attribution_aside!(data)
    return unless data[:sections].present?

    publ_aside = data[:sections].match(ReferenceParser::Cfr::PUBL_ATTRIBUTION_ASIDE)
    return unless publ_aside

    data[:embedded_public_laws] = embedded_publ_citations(publ_aside[0])
    if (stat = ReferenceParser::Stat.embedded_from_comma_aside(publ_aside[0]))
      after_aside = data[:sections][publ_aside.end(0)..]
      if after_aside.blank? || !after_aside.match?(/\A\s*,\s*\d/)
        data[:embedded_stats] = [stat]
      end
    end
    data[:sections_before_publ_aside] = data[:sections][0...publ_aside.begin(0)].scan(/\d+(?:\.\d+)?(?:[a-z]{1,5})?/i).length
    data[:sections] = data[:sections].sub(publ_aside[0], "")
  end

  def self.normalize_sections_list_text(clean)
    delta = 0
    # "318-318d. 486" — period used as list separator (not Chap./App./seq.)
    clean = clean.gsub(/(\d[a-z]{0,5})\.\s+(?=\d)/i, '\1, ')
    clean = clean.gsub(/(\d+[a-z]?)\s+and\s+(notes?)\b/i) do
      delta -= ($&.length - "#{$1}, #{$2}".length)
      "#{$1}, #{$2}"
    end
    # before stripping "chapter N", collapse "subchapters … of chapter N" to the chapter number
    clean = clean.gsub(/(?:,\s*|\s+)subchapters?\s+[IVXLCDM]+(?:\s*(?:,|and|&)\s*[IVXLCDM]+)*\s+of\s+chapter\s+(\d+)/i) do
      replacement = ", #{$1}"
      delta -= ($&.length - replacement.length)
      replacement
    end
    # "Chap. 56 Section 5604" — drop chapter locator; keep the section number
    clean = clean.gsub(ReferenceParser::Cfr::CHAP_N_SECTION_ASIDE) do
      replacement = ", "
      delta -= ($&.length - replacement.length)
      replacement
    end
    clean = clean.gsub(/\bchapters?\s+(?=\d)/i) do
      delta -= $&.length
      ""
    end
    clean = clean.gsub(ReferenceParser::Cfr::EXPLANATORY_PARENTHETICAL) do
      delta -= $&.length
      ""
    end
    clean = clean.gsub(ReferenceParser::Cfr::REPEALED_PARENTHETICAL) do
      delta -= $&.length
      ""
    end
    clean = clean.gsub(/\s*\(\s*(notes?)\s+and\s+(\d+[a-z]?)\s*\)/i) do
      replacement = " (#{$1}), #{$2}"
      delta -= ($&.length - replacement.length)
      replacement
    end
    clean = clean.gsub(/(?:\A|(?<=\band\s)|,\s*)(\d+)\)\s*,/) do
      delta -= 1
      "#{$1},"
    end
    clean = clean.gsub(/(?:\A|(?<=\band\s)|,\s*)(\d+)\)\s*(?=and\b)/i) do
      delta -= 2
      $1
    end
    [clean, delta]
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
    delta = 0
    items = items.reject do |item|
      if item.match?(/\A\d+[a-z]+\d+\z/i)
        delta -= item.length
        true
      end
    end
    items = items.flat_map do |item|
      if (match = item.match(ET_SEQ_SECTION_BREAK))
        left = item[0...match.begin(0)] + match[1] + ". "
        right = item[match.end(0)..]
        delta -= (item.length - left.length - right.length)
        [left, right]
      else
        [item]
      end
    end
    [items, delta]
  end

  def self.preserve_spaced_section_parts?(left, right)
    left&.match?(/\d\s*\z/) && right&.match?(/\A[a-z]{1,5}\z/i)
  end

  private

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

  # relocates fragment to the suffix, before any existing list continuation ("and (b)...")
  def push_to_suffix!(captures, fragment, appended: fragment)
    captures[:suffix] = if captures[:suffix].to_s.match?(/\A\s+(?:and|or|&)\s+\([a-z]{1,5}\)/i)
      "#{fragment}#{captures[:suffix]}"
    else
      (captures[:suffix] || "") + appended
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
