class ReferenceParser::Replacement
  attr_accessor :regexp,
                :parser,
                :if_clause,
                :prepend_pattern,
                :debug_pattern

  delegate :link, 
           :link_options,
           :url, 
           :slug,
           :options,
           to: :parser

  def initialize(regexp=nil, if: nil, context_expected: nil, prepend_pattern: false, debug_pattern: false, &block)
    @regexp = regexp
    @prepend_pattern = prepend_pattern
    @debug_pattern = debug_pattern
    @context_expected = context_expected
    @if_clause = binding.local_variable_get(:if)
  end

  def clean_up_named_captures(captures, options: {})
    parser&.clean_up_named_captures(captures, options: (options || {}).reverse_merge({context_expected: @context_expected}))
  end

  def regexp
    result = @regexp.respond_to?(:call) ? @regexp.call(options&.[](:context) || {}, options || {}) : @regexp
    puts "result #{result}" if @debug_pattern && parser&.debugging
    result
  end

  def describe
    "#{parser&.class&.name} prepend_pattern #{prepend_pattern} #{@regexp.to_s&.gsub("\n", "")&.[](0..48)}"
  end

  def inspect
    "#{self.object_id} #{describe}"
  end
end
