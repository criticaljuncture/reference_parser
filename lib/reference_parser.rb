# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash"
require "action_view"

require_relative "reference_parser/all"

class ReferenceParser
  class ParseError < StandardError; end
  class ParseTimeout < StandardError; end  

  def initialize(only: nil, except: [], options: {})
    parser_types = [(only || options[:only] || default_parser_types)].flatten - except
    @options = options
    @debugging = false
    @parsers, @dependencies = parsers_for(parser_types)
    @parsers.each{ |parser| parser.normalize_options(build_options(parser, @options, {})) }
  end

  def hyperlink(text, options: {}, default: {})
    perform(text) do |parser, citation|
      build_link(parser, citation, citation[:text], build_options(parser, options, default))
    end
  end

  def each(text, options: {}, default: {}, &block)
    perform(text) do |parser, citation|
      original_text = citation[:text]
      citation[:link] = build_link(parser, citation, citation[:text], build_options(parser, options, default))
      yield(citation) if block_given?
      citation[:link] = build_link(parser, citation, citation[:text], build_options(parser, options, default)) if citation[:text] != original_text
      citation[:link]
    end
  end

  def render(parser_details, options: {}, default: {})
    result = "".html_safe
    parser_details.each do |parser, details|
      parser = new_parser(parser)
      details[:citations].each do |citation|
        citation = citation.to_h.symbolize_keys
        result << build_link(parser, citation, parser.title_for(citation), build_options(parser, options, default))
      end
    end
    result
  end

  def self.cfr_best_guess_hierarchy(text)
    guess = nil
    ReferenceParser.new(only: :cfr, options: {cfr: {best_guess: true, prefer_part: true}}).each(text) do |citation|
      guess = citation[:hierarchy].compact
      break
    end
    raise ParseError unless guess
    guess    
  end

  private

  def default_parser_types
    %i'cfr usc federal_register executive_order public_law patent email url'
  end

  def new_parser(parser_type)
    case parser_type
    when Class
      parser_type
    when Symbol
      "ReferenceParser::#{parser_type.to_s.titleize.tr(' ', '')}".constantize
    end.new(@options, debugging: @debugging)    
  end

  def parsers_for(parser_types)
    parsers, dependencies = [], []
    parser_types.map do |parser_type|
      parser = new_parser(parser_type)
      if parser.depends_on_parser && !parser_types.include?(parser.depends_on_parser)
        dependencies << parser.depends_on_parser
        parsers << new_parser(parser.depends_on_parser).tap{|p| p.dependency = true}
      end
      parsers << parser
    end
    [parsers, dependencies]
  end

  def determine_effective_parser(parser, citation)
    return parser if !citation[:source] || (parser&.slug == citation[:source])
    result = @parsers.detect{ |parser| parser.slug == citation[:source] }
    yield(result) if result && block_given?
    result
  end  

  def perform(text, options: {}, &block)
    replacements = replacements_for(@options)
    return text || "" unless text && replacements.present?
    
    Timeout::timeout(20) do
      text = replace_patterns(text, replacements: replacements, options: options, &block)
    end

    text
  rescue Timeout::Error
    puts "timeout @options #{@options}" if @debugging
    raise ParseTimeout
  end

  def replace_patterns(text, replacements: [], options: {}, &block)
    @references = []
    searchable_text = text.to_str
    searchable_text.gsub(merge_patterns_from(replacements)) do
      match = Regexp.last_match
      all_captures = match.captures
      result = nil
      replacements.each do |replacement|
        next unless replacement.regexp

        # take captures associated with this replacement pattern
        captures = all_captures.shift(replacement.regexp.names.size)
        
        # skip ahead unless this pattern has captures present
        next unless captures.any?{|x| !x.nil?}

        # only captures used by this replacement
        named_captures = match.named_captures.slice(*replacement.regexp.names).to_h.symbolize_keys
        if replacement.will_consider_post_match
          named_captures[:post_match] = searchable_text[match.end(0)..match.end(0)+64]
          named_captures[:pattern_slug] = replacement.pattern_slug
        end
        citations = replacement.clean_up_named_captures(named_captures, options: build_options(replacement.parser, @options, {}))
        citations = :skip if replacement.ignore?(citations, options: build_options(replacement.parser, @options, {}))
        break if citations == :skip

        # simple implementations just update the captures in place
        citations = named_captures unless citations.is_a?(Array) || citations.is_a?(Hash)
        citations = [citations] unless citations.is_a?(Array)

        citations&.each do |citation|

          effective_parser = determine_effective_parser(replacement.parser, citation) do |effective_parser|
            effective_parser.clean_up_named_captures(citation, options: build_options(effective_parser, @options, {}))
          end

          unless effective_parser
            citation = {text: match[0], result: match[0]} 
          else
            citation_result = nil
            if block_given?
              citation[:text] = citation[:text] || match[0]
              prefix = citation[:prefix] || ''
              prefix_spacers, suffix_spacers = eject_spacers_from_tag(citation[:text], aggressive: true)
              suffix = citation[:suffix] || ''
              citation_result = "".html_safe << 
                                prefix << 
                                prefix_spacers <<
                                (yield(effective_parser, citation) || '') <<
                                suffix_spacers << 
                                suffix
            end
            if citation_result
              result ||= "".html_safe
              result << citation_result  
              citation[:result] = citation_result
            end
          end

        end
        break
      end
      result.gsub!('"', "'") if result.respond_to?(:gsub!) # match fixture html quoting
      result || match[0]
    end.html_safe # !?
  end  

  ALL_DIVIDER_PATTERN = /(?<split>(,|\s+|and|or|through)+)/ix
  COMMA_WHITESPACE_PATTERN = /[\s,]+/ix

  def eject_spacers_from_tag(text, aggressive: false)
    prefix = suffix = ""

    pattern = aggressive ? ALL_DIVIDER_PATTERN : COMMA_WHITESPACE_PATTERN

    prefix_match = /\A#{pattern}/.match(text)
    if prefix_match
      text.delete_prefix!(prefix_match[0])
      prefix = prefix_match[0]
    end
    
    suffix_match = /#{pattern}\z/.match(text)
    if suffix_match
      text.delete_suffix!(suffix_match[0])
      suffix = suffix_match[0]
    end     

    [prefix, suffix]
  end

  def build_options(parser, options, default)
    return default unless parser
    default.merge(options[parser.slug] || {})
  end

  def build_link(parser, citation, str, options)
    parser.link_to(str, citation, options)    
  end

  def merge_patterns_from(replacements)
    patterns = replacements.map(&:regexp).compact
    Regexp.union(patterns)
  end

  def replacements_for(options)
    all = @parsers.flat_map(&:replacements)

    if @debugging
      debug = all.detect{ |r| r.debug_pattern }
      return [debug] if debug.present?
    end

    # move prepend_pattern replacements to the front    
    prepended, other = all.partition(&:prepend_pattern)

    # check if_clauses
    results = [prepended, other].flatten.select do |replacement|
      case replacement.if_clause
      when nil, false
        true
      when Symbol
        replacement.parser&.send(replacement.if_clause, build_options(replacement.parser, options, {}))
      end
    end

    results.compact
  end
end
