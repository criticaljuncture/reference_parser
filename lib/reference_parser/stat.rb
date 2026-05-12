class ReferenceParser::Stat < ReferenceParser::Authority
  # United States Statutes at Large

  replace(/(?<volume>[0-9]{1,3})\s*Stat\.?\s*(?<chapters>[0-9]{1,5}(?:-[0-9]{1,5})?(?:,\s*[0-9]{1,5}(?:-[0-9]{1,5})?)*(?:,\s*sec\.\s*[0-9]+)?)/i, pattern_slug: :stat)

  def handles_lists
    true
  end

  def clean_up_named_captures(captures, options: {})
    captures[:chapter] = captures.delete(:chapters)
    if captures[:chapter].include?(",")
      citations = []
      captures[:chapter].split(",").each do |chapter|
        if (chapter = chapter.strip).present?
          citations << captures.dup.tap { it[:chapter] = chapter }
        end
      end
      citations
    end
  end

  def slug
    :stat
  end
end
