module ReferenceParser::CfrAliases
  HIERARCHY_ALIASES = {}

  FAR_CHAPTERS = {
    # "1" ................................................ FAR
    "2" => {structure: :overlay, name: "DFARS"}, # ....... Defense Federal Acquisition Regulation Supplement ................... overlay ex: 48/201.201-1
    "3" => {structure: :overlay, name: "HHSAR"}, # ....... Department of Health and Human Services Acquisition Regulation ...... overlay ex: 48/301.602-3
    "4" => {structure: :replacement, name: "AGAR"}, # .... Department of Agriculture's Acquisition Regulation
    "5" => {structure: :custom, name: "GSAR"}, # ......... General Services Acquisition Regulation ............................. clause  ex: 48/552.203-71
    "6" => {structure: :overlay, name: "DOSAR"}, # ....... Department of State Acquisition Regulation .......................... overlay ex: 48/601.602-3
    "7" => {structure: :replacement, name: "AIDAR"}, # ... USAID Acquisition Regulation
    "8" => {structure: :overlay, name: "VAAR"}, # ........ Department of Veterans Affairs Acquisition Regulation ............... overlay ex: 48/814.202-4
    "9" => {structure: :overlay, name: "DEAR"}, # ........ Department of Energy Acquisition Regulation ......................... overlay ex: 48/901.602-3
    "10" => {structure: :overlay, name: "DTAR"}, # ....... Department of the Treasury Acquisition Regulation ................... overlay ex: 48/1009.104-5
    "12" => {structure: :overlay, name: "TAR"}, # ........ Department of Transportation, Transportation Acquisition Regulation . overlay ex: 48/1201.201-1
    "13" => {structure: :replacement, name: "CAR"}, # .... Department of Commerce Acquisition Regulation
    "14" => {structure: :replacement, name: "DIAR"}, # ... Department of the Interior Acquisition Regulation
    "15" => {structure: :replacement, name: "EPAAR"}, # .. Environmental Protection Agency Acquisition Regulations
    "16" => {structure: :replacement, name: "FEHBAR"}, # . Federal Employees Health Benefits Acquisition Regulation
    # "17" ............................................... unnamed
    "18" => {structure: :overlay, name: "NFS"}, # ........ NASA FAR Supplement ................................................. overlay ex: 48/1801.105-1
    "19" => {structure: :replacement, name: "IAAR"}, # ... Broadcasting Board of Governors Acquisition Regulation
    "20" => {structure: :replacement, name: "NRCAR"}, # .. Nuclear Regulatory Commission Acquisition Regulation
    "21" => {structure: :replacement, name: "LIFAR"}, # .. Life Insurance Federal Acquisition Regulation
    "23" => {structure: :replacement, name: "SSAR"}, # ... Social Security Acquisition Regulation
    "24" => {structure: :overlay, name: "HUDAR"}, # ...... HUD Acquisition Regulation .......................................... overlay ex: 48/2405.202
    "25" => {structure: :replacement, name: "NSFAR"}, # .. National Science Foundation Acquisition Regulations
    "28" => {structure: :replacement, name: "JAR"}, # .... Justice Acquisition Regulation
    "29" => {structure: :replacement, name: "DOLAR"}, # .. Department of Labor Acquisition Regulation
    "30" => {structure: :overlay, name: "HSAR"}, # ....... Department of Homeland Security Acquisition Regulation .............. overlay ex: 48/3006.302-1
    "34" => {structure: :overlay, name: "EDAR"} # ........ Department of Education Acquisition Regulations ..................... overlay ex: 48/3405.205
    # "51" ............................................... reserved
    # "52" ............................................... unnamed
    # "53" ............................................... reserved
    # "54" ............................................... unnamed
    # "57" ............................................... unnamed
    # "61" ............................................... unnamed
    # "99" ............................................... unnamed
  }

  FAR_CHAPTERS.each do |far_chapter, config|
    HIERARCHY_ALIASES[config[:name]] = {pattern: /\b#{config[:name].chars.map { |c| "#{c}\\.?\\s*" }.join}\b/ix, hierarchy: {title: "48", chapter: far_chapter}}
  end

  {
    "FAR" => {
      pattern: /\b#{"FAR".chars.map { |c| "#{c}\\.?\\s*" }.join}\b/ix,
      hierarchies: [
        {title: "14"}, {title: "48", chapter: "1"}
      ]
    },
    "FMR" => {
      pattern: /\b#{"FMR".chars.map { |c| "#{c}\\.?\\s*" }.join}\b/ix,
      hierarchies: [
        {title: "41"}
      ]
    }
  }.each do |acronym, config|
    HIERARCHY_ALIASES[acronym] = config
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def alternate_reference_for(hierarchy)
      matched_hierarchy = nil
      alias_text = nil
      HIERARCHY_ALIASES.each do |hierarchy_alias|
        alias_text, definition = hierarchy_alias
        matched_hierarchy = (definition[:hierarchies] || [definition[:hierarchy]]).detect { |h| !h.detect { |k, v| hierarchy[k].to_s != v } }
        break if matched_hierarchy
      end
      ReferenceParser::Hierarchy.citation(hierarchy, alias_hierarchy: matched_hierarchy, alias_text: alias_text) if matched_hierarchy
    end

    def known_overlay_chapter?(hierarchy)
      (hierarchy[:title] == "48") && (FAR_CHAPTERS[hierarchy[:chapter]]&.[](:structure) == :overlay)
    end

    def linked_overlay_for(hierarchy)
      if (overlay = overlay_for(hierarchy)).present?
        ReferenceParser.new(only: %i[cfr]).hyperlink(overlay, options: {cfr: {relative: true}})
      end
    end

    def overlay_for(hierarchy)
      if hierarchy[:title].to_s == "48" && (chapter = hierarchy[:chapter].to_i) > 1
        offset = chapter * 100
        description = if (section = hierarchy[:section]).present? && (match = /\A(?<prefix>\d+)(?<remainder>.+)/.match(section))
          ""
        elsif (subpart = hierarchy[:subpart]).present? && (match = /\A(?<prefix>\d+)(?<remainder>.+)?/.match(subpart))
          "Subpart "
        elsif (part = hierarchy[:part]).present? && (match = /\A(?<prefix>\d+)(?<remainder>.+)?/.match(part))
          "Part "
        end

        if match && (prefix = match[:prefix].to_i)&.between?(offset, offset + 99)
          if (overlay = prefix - offset) > 0
            "48 CFR #{description}#{overlay}#{match[:remainder]}"
          end
        end
      end
    end
  end
end
