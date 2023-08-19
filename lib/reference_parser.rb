# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash"
require "action_view"

require_relative "reference_parser/all"

class ReferenceParser
  class ParseError < StandardError; end

  class ParseTimeout < StandardError; end

  def initialize(only: nil, except: [], options: {})
    @options = options || {}
    @requested_parser_types = [(only || @options[:only] || default_parser_types)].flatten - except
    @timeout = @options.delete(:timeout) || 20
    @html_aware = @options[:html_awareness] != :none
    @debugging = false
    @parsers, @dependencies = parsers_for(@requested_parser_types)
    @parsers.each { |parser| parser.normalize_options(build_options(parser, @options, {})) }
  end

  def hyperlink(text, options: {}, default: {})
    perform(text, timeout: options.delete(:timeout)) do |parser, citation|
      build_link(parser, citation, citation[:text], build_options(parser, options, default))
    end
  end

  def each(text, options: {}, default: {}, &block)
    perform(text, timeout: options.delete(:timeout)) do |parser, citation|
      original_text = citation[:text]
      citation[:link] = build_link(parser, citation, citation[:text], build_options(parser, options, default))
      yield(citation) if block && (citation[:link] != citation[:text])
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

  def self.cfr_parser
    @cached_cfr ||= ReferenceParser.new(only: %i[cfr])
  end

  def self.cfr_best_guess_hierarchy_parser
    @cfr_best_guess_hierarchy_parser ||= ReferenceParser.new(only: :cfr, options: {cfr: {best_guess: true, allow_aliases: true, prefer_part: true}})
  end

  def self.cfr_best_guess_hierarchy(text)
    cfr_best_guess_hierarchy_parser.guess_hierarchy(text)
  end

  def self.cfr_best_guess_hierarchies(text)
    cfr_best_guess_hierarchy_parser.guess_hierarchies(text)
  end

  def guess_hierarchy(text)
    guess_hierarchies(text, first: true).first
  end

  def guess_hierarchies(text, first: false)
    guesses = []
    each(text) do |citation|
      if (guess = citation[:hierarchy])
        guesses << cleanup_guess(guess, citation)
      elsif (guess = citation[:ambiguous])
        guess.each do |ambiguous_guess|
          guesses << cleanup_guess(ambiguous_guess, citation)
        end
      end
      break if first
    end

    raise ParseError unless guesses.present?

    guesses
  end

  private

  def apply_hint_corrections(modified_text, hint_corrections)
    puts Rainbow("hint_corrections ").blue + Rainbow(hint_corrections).orange if @debugging
    hint_corrections.each do |a, b|
      modified_text.gsub!(a, b)
    end
    modified_text
  end

  def cleanup_guess(guess, citation)
    return unless guess

    guess = guess.compact
    if guess[:appendix].present? && (href_appendix = citation.dig(:href_hierarchy, :appendix))
      guess[:appendix] = href_appendix.gsub("%20", " ")
    end
    if guess[:paragraph].present?
      guess[:paragraph] = "#{ReferenceParser::Cfr.section_string(guess)}#{guess[:paragraph]}"
    end
    guess
  end

  def default_parser_types
    %i[usc email dfars_pgi cfr federal_register executive_order public_law patent url]
  end

  def new_parser(parser_type)
    case parser_type
    when Class
      parser_type
    when Symbol
      "ReferenceParser::#{parser_type.to_s.titleize.tr(" ", "")}".constantize
    end.new(@options, debugging: @debugging)
  end

  def parsers_for(parser_types)
    parsers, dependencies = [], []
    parser_types.map do |parser_type|
      parser = new_parser(parser_type)
      if parser.depends_on_parser && !parser_types.include?(parser.depends_on_parser)
        dependencies << parser.depends_on_parser
        parsers << new_parser(parser.depends_on_parser).tap { |p| p.dependency = true }
      end
      parsers << parser
    end
    [parsers, dependencies]
  end

  def determine_effective_parser(parser, citation)
    return parser if !citation[:source] || (parser&.slug == citation[:source])
    result = @parsers.detect { |parser| parser.slug == citation[:source] }
    yield(result) if result && block_given?
    result
  end

  def perform(text, options: {}, timeout: nil, &block)
    return text || "" unless text && replacements.present?
    Timeout.timeout(timeout || @timeout) do
      text = replace_patterns(text, options: options, &block)
    end

    text
  rescue Timeout::Error
    puts "timeout @options #{@options}" if @debugging
    raise ParseTimeout
  end

  def replacements
    @replacements ||= replacements_for(@options)
  end

  def merged_patterns
    @merged_patterns ||= merge_patterns_from(replacements)
  end

  def replace_patterns(text, options: {}, &block)
    @references = []
    searchable_text = text.to_str
    return text unless searchable_text

    tag_context = ReferenceParser::TagContext.new(searchable_text, @html_aware)

    hint_corrections = []

    modified_text = searchable_text.gsub(merged_patterns) do
      match = Regexp.last_match
      all_captures = match.captures
      result = nil

      tag_context.consider(match)

      if !@html_aware || tag_context.linkable?
        replacements.each.with_index do |replacement, index|
          next unless replacement.regexp

          # take captures associated with this replacement pattern
          captures = all_captures.shift(replacement.regexp.names.size)

          # skip ahead unless this pattern has captures present
          next unless captures.any? { |x| !x.nil? }

          puts Rainbow("[#{index}] matched #{replacement.pattern_slug ? ":#{replacement.pattern_slug}" : "<missing slug>"} \"#{match[0]}\"").green if @debugging

          # only captures used by this replacement
          named_captures = match.named_captures.slice(*replacement.regexp.names).to_h.symbolize_keys
          replacement_options = build_options(replacement.parser, @options, {})
          replacement_options[:pattern_slug] = replacement.pattern_slug if replacement.pattern_slug.present?
          replacement_options[:pre_match] = tag_context.pre_match if replacement.will_consider_pre_match
          replacement_options[:post_match] = tag_context.post_match if replacement.will_consider_post_match

          citations = replacement.clean_up_named_captures(named_captures, options: replacement_options)
          citations = :skip if replacement.ignore?(citations, options: build_options(replacement.parser, @options, {}))
          break if citations == :skip

          # simple implementations just update the captures in place
          citations = named_captures unless citations.is_a?(Array) || citations.is_a?(Hash)
          citations = [citations] unless citations.is_a?(Array)

          citations&.each do |citation|
            effective_parser = determine_effective_parser(replacement.parser, citation) do |effective_parser|
              replacement_options.merge!(build_options(effective_parser, @options, {}))
              effective_parser.clean_up_named_captures(citation, options: replacement_options)
            end

            if effective_parser && @requested_parser_types.include?(effective_parser.type_slug)
              citation_result = nil
              if block
                citation[:source] ||= effective_parser.slug
                citation[:text] = citation[:text] || match[0]
                prefix = citation[:prefix] || ""
                prefix_spacers, suffix_spacers = eject_spacers_from_tag(citation[:text], aggressive: effective_parser.handles_lists)
                suffix = citation[:suffix] || ""
                citation_result = "".html_safe <<
                  prefix <<
                  prefix_spacers <<
                  (yield(effective_parser, citation) || "") <<
                  suffix_spacers <<
                  suffix
              end
              if citation_result
                result ||= "".html_safe
                result << citation_result
                citation[:result] = citation_result
              end

              if (updated_result = resolve_url_hints(citation, replacement_options, hint_corrections))
                result = updated_result
              end
            else
              citation = {text: match[0], result: match[0]}
            end
          end
          break
        end
      end

      Thread.pass

      result || match[0]
    end
    apply_hint_corrections(modified_text, hint_corrections).html_safe # !?
  end

  def resolve_url_hints(citation, replacement_options, absorb_suffix_replacements)
    result = nil
    puts Rainbow("checking hints for ").blue + Rainbow((citation[:url]).to_s).green if @debugging
    if (hints = @options[:hints]).present?
      puts Rainbow("hints ").blue + Rainbow(@options[:hints]).green if @debugging
      hints.detect do |hint|
        replacement_url = nil

        clean_hint = space_agnostic(hint)
        clean_citation = space_agnostic(citation[:text])

        if clean_hint == clean_citation
          # url space correction needed
          replacement_url = hint
        elsif clean_hint.start_with?(clean_citation) && (remaining = space_agnostic_remainder(hint, citation[:text])) && space_agnostic(citation[:suffix] + replacement_options[:post_match]).include?(remaining)
          # url text absorption needed
          if (absorb_suffix = space_agnostic_remainder(citation[:suffix] + replacement_options[:post_match], remaining, return_prefix: true))
            puts Rainbow("absorbing ").blue + Rainbow(absorb_suffix).green if @debugging
            replacement_url = citation[:url] + remaining
            absorb_suffix_replacements << [
              "#{citation[:text]}</a>#{absorb_suffix}",
              "#{citation[:text]}#{absorb_suffix}</a>"
            ]
          end
        elsif clean_citation.start_with?(clean_hint)
          # url text ejection needed
          if (eject_suffix = space_agnostic_remainder(citation[:text], hint)) && (eject_url_suffix = space_agnostic_remainder(citation[:url], hint))
            puts Rainbow("ejecting ").blue + Rainbow(eject_suffix).green + Rainbow(" / ").blue + Rainbow(eject_url_suffix).green if @debugging
            replacement_url = citation[:url].delete_suffix(eject_url_suffix)
            absorb_suffix_replacements << [
              "#{citation[:text]}</a>#{citation[:suffix]}",
              "#{citation[:text].delete_suffix(eject_suffix)}</a>#{citation[:suffix]}#{eject_suffix}"
            ]
          end
        end

        if replacement_url
          citation[:result].gsub!('href="' + citation[:url] + '"', 'href="' + replacement_url + '"')
          citation[:url] = replacement_url
        end

        if replacement_url
          result = citation[:result]
        end
      end
    end
    result
  end

  def space_agnostic(text)
    text.gsub(/\s|&#8203;|%20/, "")
  end

  def space_agnostic_remainder(haystack, needle, return_prefix: false)
    haystack_index = 0
    haystack_length = haystack.length
    needle_index = 0
    needle_length = needle.length
    ignore = false
    while !ignore && haystack_index < haystack_length && needle_index < needle_length
      if haystack[haystack_index] == needle[needle_index]
        haystack_index += 1
        needle_index += 1
      elsif haystack[haystack_index] == " "
        haystack_index += 1
      elsif haystack[haystack_index..haystack_index + 2] == "%20"
        haystack_index += 3
      elsif haystack[haystack_index..haystack_index + 6] == "&#8203;"
        haystack_index += 7
      elsif needle[needle_index] == " "
        needle_index += 1
      elsif needle[needle_index..needle_index + 2] == "%20"
        needle_index += 3
      elsif needle[needle_index..needle_index + 6] == "&#8203;"
        needle_index += 7
      else
        ignore = true
      end
    end

    if !ignore
      if return_prefix
        haystack[..haystack_index - 1]
      else
        haystack[haystack_index..]
      end
    end
  end

  ALL_DIVIDER_PATTERN = /(?<split>(?:,|;|\s+|and|or|through)+)/ix
  TRAILING_PATTERN = /[\s,;]+/ix
  TRAILING_HTML_ENTITY_OR_ATTRIBUTE = /
    (?:
      &\#?[0-9a-zA-Z]+;
      |
      [0-9a-zA-Z]+=[0-9a-zA-Z]+;
    )
    \z
  /x

  def eject_spacers_from_tag(text, aggressive: false)
    prefix = suffix = ""

    pattern = aggressive ? ALL_DIVIDER_PATTERN : TRAILING_PATTERN

    prefix_match = /\A#{pattern}/.match(text)
    if prefix_match
      text.delete_prefix!(prefix_match[0])
      prefix = prefix_match[0]
    end

    suffix_match = /#{pattern}\z/.match(text)
    if suffix_match && !TRAILING_HTML_ENTITY_OR_ATTRIBUTE.match?(text)
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
    patterns = replacements.filter_map(&:regexp)
    Regexp.union(patterns)
  end

  def replacements_for(options)
    all = @parsers.flat_map(&:replacements)

    if @debugging
      debug = all.select { |r| r.debug_pattern }
      if debug.present?
        puts "merged pattern \n #{merge_patterns_from(debug)}"
        return debug
      end
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
