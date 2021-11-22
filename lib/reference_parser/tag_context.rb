class ReferenceParser::TagContext
  attr_accessor :pre_match, :post_match

  def initialize(text, html_aware)
    @text = text
    @html_aware = html_aware
    @open = @close = @linkable_pointer = @pointer = 0
    @pre_match = @post_match = nil
  end

  def consider(match)
    match_begin = match.begin(0)

    @pre_match = @text[([@linkable_pointer, (@html_aware ? @linkable_pointer : (match_begin - 32))].min)..([0, (match_begin - 1)].max)]
    @post_match = @text[match.end(0)..match.end(0) + 64]

    @open += @text[@pointer..match_begin].count("<")
    @close += @text[@pointer..match_begin].count(">")
    @pointer = match_begin
  end

  AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]

  def linkable?
    return false if @open > @close # current position is is the middle of tag attributes

    previously_linked = ((@pre_match =~ AUTO_LINK_CRE[0] and @post_match =~ AUTO_LINK_CRE[1]) or
      (@pre_match.rindex(AUTO_LINK_CRE[2]) and $' !~ AUTO_LINK_CRE[3]))

    result = !previously_linked
    @linkable_pointer = @pointer if result
    result
  end
end
