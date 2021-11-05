class ReferenceParser::TagContext
  attr_accessor :pre_match, :post_match

  def initialize(text, html_aware)
    @text = text
    @html_aware = html_aware
    @pointer = 0
    @pre_match = @post_match = nil
  end

  def consider(match)
    @pre_match = @text[([@pointer, (@html_aware ? 0 : (match.begin(0) - 32))].max)..([0, (match.begin(0) - 1)].max)]
    @post_match = @text[match.end(0)..match.end(0) + 64]
  end

  AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]

  def linkable?
    previously_linked = ((@pre_match =~ AUTO_LINK_CRE[0] and @post_match =~ AUTO_LINK_CRE[1]) or
      (@pre_match.rindex(AUTO_LINK_CRE[2]) and $' !~ AUTO_LINK_CRE[3]))

    !previously_linked
  end
end
