class ReferenceParser::TagContext
  UNAWARE_PRE_MATCH_BYTES = 32
  POST_MATCH_CHARS = 65
  MAX_BYTES_PER_CHAR = 4
  LINE_BROKEN_TAG = /<(?=[^>]+?(\n))/
  ANCHOR_OPEN = /<a\b(?=.*?(>))/i
  ANCHOR_CLOSE = /<\/a>/i
  ANCHOR_CLOSE_BYTES = 4

  def initialize(text, html_aware)
    @text = text
    @html_aware = html_aware
    @open = @close = @match_begin = @match_end = @linkable_pointer = @pointer = @pre_match_begin = 0
    @last_lt = @last_gt = -1
    @pre_match = @post_match = nil
    @ignorable = @ignorable_match = false
  end

  def consider(match)
    @match_begin, @match_end = match.byteoffset(0)
    @pre_match = @post_match = nil

    prior = @match_begin.zero? ? @text : @text.byteslice(@pointer, @match_begin - @pointer)
    @open += prior.count("<")
    @close += prior.count(">")
    track_last_brackets(prior) unless @match_begin.zero?
    @ignorable_group = match.names.include?("ignorable") if @ignorable_group.nil?
    @ignorable_match = @ignorable_group && match[:ignorable].present?
    @ignorable = @ignorable_match || @open > @close # current position is is the middle of tag attributes
    @pre_match_begin = @html_aware ? @linkable_pointer : char_boundary_at_or_before(@match_begin - UNAWARE_PRE_MATCH_BYTES)

    @pointer = @match_begin
  end

  def linkable?
    return false if @ignorable

    previously_linked = !@match_begin.zero? &&
      ((post_match.include?(">") && inside_tag?) || inside_anchor?)

    result = !previously_linked
    @linkable_pointer = @pointer if result
    result
  end

  def pre_match
    return if @ignorable_match

    @pre_match ||= if @ignorable
      ""
    elsif @match_begin.zero?
      @text[0]
    else
      @text.byteslice(@pre_match_begin, @match_begin - @pre_match_begin)
    end
  end

  def post_match
    @post_match ||= @ignorable ? "" : @text.byteslice(@match_end, POST_MATCH_CHARS * MAX_BYTES_PER_CHAR)[0, POST_MATCH_CHARS]
  end

  private

  def track_last_brackets(prior)
    lt = prior.byterindex("<")
    gt = prior.byterindex(">")
    @last_lt = @pointer + lt if lt
    @last_gt = @pointer + gt if gt
  end

  def inside_tag?
    line_broken_tag_before_match? || unclosed_tag_before_match?
  end

  def line_broken_tag_before_match?
    _, newline = line_broken_tags.bsearch { |lt, _| lt >= @pre_match_begin }
    newline && newline < @match_begin
  end

  def unclosed_tag_before_match?
    tag_begin = (@last_lt < @match_begin - 1) ? @last_lt : lt_at_or_before(@match_begin - 2)
    tag_begin >= @pre_match_begin && tag_begin > @last_gt
  end

  def inside_anchor?
    index = anchor_opens.bsearch_index { |_, open_end| open_end > @match_begin } || anchor_opens.size
    return false if index.zero?

    open_begin, open_end = anchor_opens[index - 1]
    return false if open_begin < @pre_match_begin

    close = anchor_closes.bsearch { |close_begin| close_begin >= open_end }
    close.nil? || close + ANCHOR_CLOSE_BYTES > @match_begin
  end

  def line_broken_tags
    @line_broken_tags ||= scan_offsets(LINE_BROKEN_TAG) { |m| [m.byteoffset(0)[0], m.byteoffset(1)[0]] }
  end

  def anchor_opens
    @anchor_opens ||= scan_offsets(ANCHOR_OPEN) { |m| [m.byteoffset(0)[0], m.byteoffset(1)[1]] }
  end

  def anchor_closes
    @anchor_closes ||= scan_offsets(ANCHOR_CLOSE) { |m| m.byteoffset(0)[0] }
  end

  def scan_offsets(pattern)
    offsets = []
    @text.scan(pattern) { offsets << yield($~) }
    offsets
  end

  def lt_at_or_before(offset)
    return -1 if offset.negative?

    @text.byterindex("<", char_boundary_at_or_before(offset)) || -1
  end

  def char_boundary_at_or_before(offset)
    return 0 if offset <= 0
    offset -= 1 while offset > 0 && (@text.getbyte(offset) & 0xC0) == 0x80
    offset
  end
end
