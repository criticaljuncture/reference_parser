require "spec_helper"
require_relative "url_examples"

RSpec.describe ReferenceParser::UrlPrtpage do
  it_behaves_like "url examples"

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

  context "with spaces in links" do
    scenarios = [
      {description: "PDF w/ spaces",
       source: "<em>www.energy.gov/sites/prod/files/2016/12/f34/Summary of Public Input Report FINAL.pdf</em>",
       expected: 'Lorem ipsum dolor sit <em><a href="http://www.energy.gov/sites/prod/files/2016/12/f34/Summary%20of%20Public%20Input%20Report%20FINAL.pdf">www.energy.gov/&#8203;sites/&#8203;prod/&#8203;files/&#8203;2016/&#8203;12/&#8203;f34/&#8203;Summary of Public Input Report FINAL.pdf</a></em> amet, consectetuer adipiscing elit.'},
      {description: "link in italics w/ text",
       source: "<em>http://www.wlrk.com/files/2015/NominatingandCorporateGovernanceCommitteeGuide2015.pdf. See also</em>",
       expected: 'Lorem ipsum dolor sit <em><a href="http://www.wlrk.com/files/2015/NominatingandCorporateGovernanceCommitteeGuide2015.pdf">http://www.wlrk.com/&#8203;files/&#8203;2015/&#8203;NominatingandCorporateGovernanceCommitteeGuide2015.pdf</a>. See also</em> amet, consectetuer adipiscing elit.'},
      {description: "multiple links in italics",
       source: "<em>See http://www.reginfo.gov/public/do/eAgendaViewRule?pubId=200904&amp;RIN=1215-AB75 and http://www.reginfo.gov/public/do/eAgendaViewRule?pubId=200904&amp;RIN=1215-AB75</em>",
       expected: 'Lorem ipsum dolor sit <em>See <a href="http://www.reginfo.gov/public/do/eAgendaViewRule?pubId=200904&amp;RIN=1215-AB75">http://www.reginfo.gov/&#8203;public/&#8203;do/&#8203;eAgendaViewRule?&#8203;pubId=&#8203;200904&amp;&#8203;RIN=&#8203;1215-AB75</a> and <a href="http://www.reginfo.gov/public/do/eAgendaViewRule?pubId=200904&amp;RIN=1215-AB75">http://www.reginfo.gov/&#8203;public/&#8203;do/&#8203;eAgendaViewRule?&#8203;pubId=&#8203;200904&amp;&#8203;RIN=&#8203;1215-AB75</a></em> amet, consectetuer adipiscing elit.'},
      {descripton: "avoids trailing punctuation",
       source: "<em>https://www.vaneck.com/library/vaneck-vectors-etfs/gdx-fact-sheet-pdf/. (</em>",
       expected: 'Lorem ipsum dolor sit <em><a href="https://www.vaneck.com/library/vaneck-vectors-etfs/gdx-fact-sheet-pdf/">https://www.vaneck.com/&#8203;library/&#8203;vaneck-vectors-etfs/&#8203;gdx-fact-sheet-pdf/&#8203;</a>. (</em> amet, consectetuer adipiscing elit.'},
      {descripton: "avoids linking text",
       source: "A fillable .pdf version of the form is available",
       expected: "Lorem ipsum dolor sit A fillable .pdf version of the form is available amet, consectetuer adipiscing elit."},
      {descripton: "handles anchor",
       source: "<em>https://www.ftc.gov/system/files/documents/public_statements/1566385/statement_by_commissioners_wilson_and_chopra_re_hsr_6b.pdf#:~:text=Statement%20of%20Commissioner%20Christine%20S.%20Wilson%2C%20Joined%20by,that%20drive%20content%20curation%20and%20targeted%20advertising%20practices.</em>",
       expected: 'Lorem ipsum dolor sit <em><a href="https://www.ftc.gov/system/files/documents/public_statements/1566385/statement_by_commissioners_wilson_and_chopra_re_hsr_6b.pdf#:~:text=Statement%20of%20Commissioner%20Christine%20S.%20Wilson%2C%20Joined%20by,that%20drive%20content%20curation%20and%20targeted%20advertising%20practices">https://www.ftc.gov/&#8203;system/&#8203;files/&#8203;documents/&#8203;public_&#8203;statements/&#8203;1566385/&#8203;statement_&#8203;by_&#8203;commissioners_&#8203;wilson_&#8203;and_&#8203;chopra_&#8203;re_&#8203;hsr_&#8203;6b.pdf#:~:text=&#8203;Statement%20of%20Commissioner%20Christine%20S.%20Wilson%2C%20Joined%20by,that%20drive%20content%20curation%20and%20targeted%20advertising%20practices</a>.</em> amet, consectetuer adipiscing elit.'}
    ]

    scenarios.each do |scenario|
      it "handles #{scenario[:description]}" do
        result = hyperlink("Lorem ipsum dolor sit #{scenario[:source]} amet, consectetuer adipiscing elit.")

        expect(result).to eq(scenario[:expected])
      end
    end
  end

  context "when on production" do
    it "doesn't timeout on" do
      expect {
        hyperlink(%(Written comments and recommendations for the proposed information collection should be sent within 30 days of publication of this notice to www.reginfo.gov/public/do/PRAMain. Find this particular information collection by selecting ``Currently under 30-day Review-- Open for Public Comments'' or by using the search function. Refer to ``Clearance for A-11 Section 280 Improving Customer Experience Information Collection'' in any correspondence.))
      }.not_to raise_error
    end

    it "doesn't duplicate commas" do
      result = hyperlink(<<~XML)
        <P>
          Persons with access to the internet may obtain the draft guidance at either
          <E T="03">https://www.fda.gov/drugs/guidance-compliance-regulatory-information/guidances-drugs, https://www.fda.gov/regulatory-information/search-fda-guidance-documents,</E>
          or
          <E T="03">https://www.regulations.gov.</E>
        </P>
      XML

      expect(result).not_to include(",,")
      expect(result).to eq(<<~LINKED)
        <P>
          Persons with access to the internet may obtain the draft guidance at either
          <E T="03"><a href="https://www.fda.gov/drugs/guidance-compliance-regulatory-information/guidances-drugs">https://www.fda.gov/&#8203;drugs/&#8203;guidance-compliance-regulatory-information/&#8203;guidances-drugs</a>, <a href="https://www.fda.gov/regulatory-information/search-fda-guidance-documents">https://www.fda.gov/&#8203;regulatory-information/&#8203;search-fda-guidance-documents</a>,</E>
          or
          <E T="03"><a href="https://www.regulations.gov">https://www.regulations.gov</a>.</E>
        </P>
      LINKED
    end
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
