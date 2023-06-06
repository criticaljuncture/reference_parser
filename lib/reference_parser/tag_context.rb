class ReferenceParser::TagContext
  def initialize(text, html_aware)
    @text = text
    @chars = @text.chars
    @html_aware = html_aware
    @open = @close = @match_begin = @match_end = @linkable_pointer = @pointer = 0
    @pre_match = @post_match = nil
    @ignorable = false
  end

  def consider(match)
    @match_begin = match.begin(0)
    @match_end = match.end(0)
    @pre_match = @post_match = nil

    @open += (prior_chars = @chars[@pointer..@match_begin - 1]).count("<")
    @close += prior_chars.count(">")
    unless (@ignorable = match.names.include?("ignorable") && match[:ignorable].present?)
      @pre_match = if (@ignorable = @open > @close) # current position is is the middle of tag attributes
        ""
      else
        @chars[([@linkable_pointer, (@html_aware ? @linkable_pointer : (@match_begin - 32))].min)..([0, (@match_begin - 1)].max)].join
      end
    end

    @pointer = @match_begin
  end

  AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]

  def linkable?
    return false if @ignorable

    previously_linked = ((pre_match =~ AUTO_LINK_CRE[0] && post_match =~ AUTO_LINK_CRE[1]) ||
      (pre_match.rindex(AUTO_LINK_CRE[2]) && $' !~ AUTO_LINK_CRE[3]))

    result = !previously_linked
    @linkable_pointer = @pointer if result
    result
  end

  attr_reader :pre_match

  def post_match
    @post_match ||= @ignorable ? "" : @chars[@match_end..@match_end + 64].join
  end
end
