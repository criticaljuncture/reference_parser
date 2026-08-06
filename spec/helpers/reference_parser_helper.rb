module ReferenceParserHelper
  PARSERS = {}

  def reference_parser_for(only: nil, options: {})
    # avoid pattern compliation for each example while respecting options
    PARSERS[[only, options.dup]] ||= ReferenceParser.new(only: only, options: options)
  end
end
