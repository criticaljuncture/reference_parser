require_relative "registration"

class ReferenceParser::Base
  include ReferenceParser::Registration

  attr_accessor :options

  def initialize(options, debugging: false)
    @debugging = debugging
    @options = options&.[](slug) || {}
  end

  def clean_up_named_captures(captures, options: {})
  end

  def link_options(citation)
    { class: default_link_classes, target: "_blank" }
  end

  def default_link_classes
    [slug, "external"].compact.join(" ")
  end

  def link_to(text, citation, options={})
    if href = url(citation, options)
      # !TODO link_to vs content_tag, this will swap href & class breaking file fixtures
      # helpers.link_to(text.html_safe, href.html_safe, **get_link_options(citation, options))
      helpers.content_tag(:a, text.html_safe, **{href: href.html_safe}.merge(get_link_options(citation, options)))      
    else
      text
    end
  end

  def slug
    self.class.name.to_s.split("::").last.underscore.to_sym
  end

  private

  def helpers
    ActionController::Base.helpers
  end

  def absolute?(url_options)
    !url_options[:relative] || url_options[:absolute]
  end

  def get_link_options(citation, options)
    result = link_options(citation)
    result = result.call(citation) if result.respond_to?(:call)
    
    to_delete = options.select{ |k,v| !v }.keys
    result = options.reverse_merge(result).except(*to_delete)

    if (result[:target] == "_blank") && !result[:rel].present?
      result[:rel] = "noopener noreferrer" 
      # this is done automatically by safe_target_blank for
      # link_to but cfr parser is using content tag to avoid
      # reversing href & class attribute order (breaking
      # exsiting test fixtures), patching it in here for the
      # moment
    end

    result.except(:on, :current, :absolute, :relative, :between, :compare)
  end
end
