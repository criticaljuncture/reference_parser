class ReferenceParser::FederalRegisterDocNumber < ReferenceParser::Base
  replace(/
    (?:FR\s*Doc
    (?:\.|ument)?\s*
    (?:Number|No\.?|\#)?[:,\s]*)
    (?:\(FR\sDoc\))?\s*
    (?<doc_number>[A-Z0-9]+[-–—][0-9]+(?:[-–—][0-9]+)?)
    \b
    /ix, pattern_slug: :fr_doc_number)

  def url(citation, url_options = {})
    if citation[:doc_number].present? && linkable_document_number?(citation[:doc_number])
      result = +""
      result << "https://www.federalregister.gov" if absolute?(url_options)
      result << "/d/#{ReferenceParser::Dashes.ascii(citation[:doc_number])}"
    end
  end

  def slug
    :fr_doc
  end

  DASH_CHARACTER_REGEX = /[-–—]/
  YEAR_WHEN_FR_DOCS_BEGIN_AVAILABILITY = 1994
  def linkable_document_number?(document_number)
    year_str = document_number.split(DASH_CHARACTER_REGEX)[0]

    if year_str.match?(/[^\d]/)
      # document numbers with non-numeric prefixes (e.g., "C1-2022-12345")
      true
    elsif year_str.length == 4
      # 4-digit year format
      year = year_str.to_i
      year >= YEAR_WHEN_FR_DOCS_BEGIN_AVAILABILITY
    elsif year_str.length == 2
      # 2-digit year format
      year = year_str.to_i
      !(30..93).cover?(year)
    else
      # Other formats are considered linkable
      true
    end
  end
end
