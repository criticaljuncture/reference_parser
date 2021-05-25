class ReferenceParser::Replacement
  attr_accessor :regexp, :parser, :prepend_pattern, :if_clause

  delegate :clean_up_named_captures, 
           :link, 
           :link_options,
           :url, 
           :slug,
           :options,
           to: :parser

  def initialize(regexp=nil, if: nil, prepend_pattern: false, debug_pattern: false, &block)
    @regexp = regexp
    @prepend_pattern = prepend_pattern
    @debug_pattern = debug_pattern
    @if_clause = binding.local_variable_get(:if)
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
