class ReferenceParser::Replacement
  attr_accessor :parser,
    :pattern_slug,
    :if_clause,
    :prepend_pattern,
    :will_consider_pre_match,
    :will_consider_post_match,
    :debug_pattern

  delegate :link,
    :link_options,
    :url,
    :slug,
    :options,
    :ignore?,
    to: :parser

  def initialize(regexp = nil, pattern_slug: nil, if: nil, context_expected: nil, will_consider_pre_match: false, will_consider_post_match: false, prepend_pattern: false, debug_pattern: false, &block)
    @regexp = regexp
    @prepend_pattern = prepend_pattern
    @debug_pattern = debug_pattern
    @context_expected = context_expected
    @will_consider_pre_match = will_consider_pre_match
    @will_consider_post_match = will_consider_post_match
    @pattern_slug = pattern_slug
    @if_clause = binding.local_variable_get(:if)
  end

  def clean_up_named_captures(captures, options: {})
    parser&.clean_up_named_captures(captures, options: (options || {}).reverse_merge({context_expected: @context_expected}))
  end

  def regexp
    @regexp.respond_to?(:call) ? @regexp.call(options&.[](:context) || {}, options || {}) : @regexp
  end

  def describe
    "#{parser&.class&.name} prepend_pattern #{prepend_pattern} #{@regexp.to_s&.delete("\n")&.[](0..48)}"
  end

  def inspect
    "#{object_id} #{describe}"
  end
end
