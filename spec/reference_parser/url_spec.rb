require "spec_helper"
require_relative "url_examples"

RSpec.describe ReferenceParser::Url do
  include_examples "url examples"

  def drop_zero_width_spaces_if_unexpected(html)
    html.gsub("&#8203;", "") # ?
  end

  def generate_result(link_text, href = nil)
    href ||= link_text
    %(<a href="#{CGI.escapeHTML(href)}">#{link_text}</a>)
  end

  def hyperlink(text, options = {})
    ReferenceParser.new(only: :url, options: {html_awareness: :careful}).hyperlink(text, default: options.reverse_merge({class: nil, target: nil}), options: {url: options})
  end
end
