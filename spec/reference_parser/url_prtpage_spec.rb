require "spec_helper"
require_relative "url_examples"

RSpec.describe ReferenceParser::UrlPrtpage do
  include_examples "url examples"

  it "handles PRTPAGE" do
    result = hyperlink(<<-XML)
      <E T="03">
        http://
        <PRTPAGE P="81301"/>
        energy.gov/fe/2015-lng-study
      </E>
    XML

    expect(result).to eql(<<-XML)
      <E T="03">
        <a href="http://energy.gov/fe/2015-lng-study">http://</a>
        <PRTPAGE P="81301"/>
        <a href="http://energy.gov/fe/2015-lng-study">energy.gov/&#8203;fe/&#8203;2015-lng-study</a>
      </E>
    XML

    result = hyperlink(<<-XML)
      <E T="03">
        http://www.energy.gov/fe/2015-
        <PRTPAGE P="81301"/>
        lng-study
      </E>
    XML

    expect(result).to eql(<<-XML)
      <E T="03">
        <a href="http://www.energy.gov/fe/2015-lng-study">http://www.energy.gov/&#8203;fe/&#8203;2015-</a>
        <PRTPAGE P="81301"/>
        <a href="http://www.energy.gov/fe/2015-lng-study">lng-study</a>
      </E>
    XML

    result = hyperlink(<<-XML)
      <E T="03">
        http://www.energy.gov/fe/2015/
        <PRTPAGE P="81301"/>
        foo/bar/baz?a=1&b=2. a very interesting piece
      </E>
    XML

    expect(result).to eql(<<-XML)
      <E T="03">
        <a href="http://www.energy.gov/fe/2015/foo/bar/baz?a=1&amp;b=2">http://www.energy.gov/&#8203;fe/&#8203;2015/&#8203;</a>
        <PRTPAGE P="81301"/>
        <a href="http://www.energy.gov/fe/2015/foo/bar/baz?a=1&amp;b=2">foo/&#8203;bar/&#8203;baz?&#8203;a=&#8203;1&amp;&#8203;b=&#8203;2</a>. a very interesting piece
      </E>
    XML
  end

  def drop_zero_width_spaces_if_unexpected(html)
    html
  end

  def generate_result(link_text, href = nil)
    href ||= link_text
    %(<a href="#{CGI.escapeHTML(href)}">#{ReferenceParser::UrlPrtpage.add_line_break_indicators(link_text)}</a>)
  end

  def hyperlink(text, options = {})
    ReferenceParser.new(only: :url_prtpage, options: {html_awareness: :careful}).hyperlink(text, default: options.reverse_merge({class: nil, target: nil}), options: {url: options})
  end
end
