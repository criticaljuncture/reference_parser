class ReferenceParser::FederalRegisterDocNumber < ReferenceParser::Base
  replace(/
    (?:FR\s*Doc
    (?:\.|ument)?\s*
    (?:Number|No\.?|\#)?[:,\s]*)
    (?:\(FR\sDoc\))?\s*
    (?<doc_number>[A-Z0-9]+-[0-9]+)
    \b
    /ix)

  def url(citation, url_options = {})
    if citation[:doc_number].present?
      result = ""
      result << "https://www.federalregister.gov" if absolute?(url_options)
      result << "/d/#{citation[:doc_number]}"
    end
  end

  def slug
    :fr_doc
  end
end
