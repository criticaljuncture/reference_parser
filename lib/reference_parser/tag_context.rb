class ReferenceParser::TagContext
  UNAWARE_PRE_MATCH_BYTES = 32
  POST_MATCH_CHARS = 65
  MAX_BYTES_PER_CHAR = 4

  def initialize(text, html_aware)
    @text = text
    @html_aware = html_aware
    @open = @close = @match_begin = @match_end = @linkable_pointer = @pointer = 0
    @pre_match = @post_match = nil
    @ignorable = false
  end

  def consider(match)
    @match_begin, @match_end = match.byteoffset(0)
    @pre_match = @post_match = nil

    prior = @match_begin.zero? ? @text : @text.byteslice(@pointer, @match_begin - @pointer)
    @open += prior.count("<")
    @close += prior.count(">")
    @ignorable_group = match.names.include?("ignorable") if @ignorable_group.nil?
    unless (@ignorable = @ignorable_group && match[:ignorable].present?)
      @pre_match = if (@ignorable = @open > @close) # current position is is the middle of tag attributes
        ""
      elsif @match_begin.zero?
        @text[0]
      else
        pre_match_begin = @html_aware ? @linkable_pointer : char_boundary_at_or_before(@match_begin - UNAWARE_PRE_MATCH_BYTES)
        @text.byteslice(pre_match_begin, @match_begin - pre_match_begin)
      end
    end

    @pointer = @match_begin
  end

  AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]

  def linkable?
    return false if @ignorable

    previously_linked = (pre_match =~ AUTO_LINK_CRE[0] && post_match =~ AUTO_LINK_CRE[1]) ||
      (pre_match.rindex(AUTO_LINK_CRE[2]) && $' !~ AUTO_LINK_CRE[3])

    result = !previously_linked
    @linkable_pointer = @pointer if result
    result
  end

  attr_reader :pre_match

  def post_match
    @post_match ||= @ignorable ? "" : @text.byteslice(@match_end, POST_MATCH_CHARS * MAX_BYTES_PER_CHAR)[0, POST_MATCH_CHARS]
  end

  private

  def char_boundary_at_or_before(offset)
    return 0 if offset <= 0
    offset -= 1 while offset > 0 && (@text.getbyte(offset) & 0xC0) == 0x80
    offset
  end
end
