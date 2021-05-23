class ReferenceParser::Patent < ReferenceParser::Base
  replace /Patent Number (?<number>[0-9,]+)/

  def url(citation, url_options={})
    "http://patft.uspto.gov/netacgi/nph-Parser?Sect2=PTO1&Sect2=HITOFF&p=1&u=/netahtml/PTO/search-bool.html&r=1&f=G&l=50&d=PALL&RefSrch=yes&Query=PN/#{citation[:number]}"
  end

  def clean_up_named_captures(captures, options: {})
    captures[:number] = captures[:number].gsub(/,/, '')
  end

  def slug
    :patent
  end
end
