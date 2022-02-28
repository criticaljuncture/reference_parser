# frozen_string_literal: true

require "spec_helper"

RSpec.describe ReferenceParser do
  let(:lorem) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit." }

  it "has a version number" do
    expect(ReferenceParser::VERSION).not_to be_nil
  end

  describe "example usage" do
    it "links partial references with context" do
      text = "please see part 300 of this title."
      expect(
        described_class.new(
          options: {
            cfr: {context: {title: "1", part: "100"}}
          }
        ).hyperlink(text, default: {relative: true, class: nil, target: nil}, options: {cfr: {on: "2020-01-01"}})
      ).to eql('please see <a href="/on/2020-01-01/title-1/part-300">part 300 of this title</a>.')
    end

    it "links to comparison pages" do
      text = "please see 1 CFR Part 2."
      expect(
        described_class.new(
          only: %i[cfr]
        ).hyperlink(text, default: {relative: true, target: "_blank"}, options: {cfr: {compare: {from: "2020-01-01", to: "2021-01-01"}}})
      ).to eql('please see <a href="/compare/2020-01-01/to/2021-01-01/title-1/part-2" class="cfr external" target="_blank" rel="noopener noreferrer">1 CFR Part 2</a>.')
    end

    it "allows customization of text" do
      text = "40 CFR 273.13, and 273.52"
      expect(
        described_class.new(
          only: %i[cfr]
        ).each(text, default: {relative: true, class: nil, target: nil}) do |citation|
          citation[:text] = "((((#{citation[:text].strip}))))"
        end
      ).to eql('<a href="/current/title-40/section-273.13">((((40 CFR 273.13))))</a>, and <a href="/current/title-40/section-273.52">((((273.52))))</a>')
    end

    it "provides absolute urls" do
      text = "please see 1 CFR Part 2."
      expect(
        described_class.new(
          only: %i[cfr]
        ).hyperlink(text, options: {cfr: {compare: {from: "2020-01-01", to: "2021-01-01"}}})
      ).to eql('please see <a href="https://www.ecfr.gov/compare/2020-01-01/to/2021-01-01/title-1/part-2" class="cfr external">1 CFR Part 2</a>.')
    end
  end

  it "does not break if there is nothing to do" do
    expect(
      described_class.new(only: []).hyperlink(lorem)
    ).to eql(lorem)
  end

  it "will only link requested items" do
    expect(
      described_class.new(only: %i[email]).hyperlink("1 CFR Part 2(n)(o)(l)(i)(n)(k) referenced by test@nil.local")
    ).to eql('1 CFR Part 2(n)(o)(l)(i)(n)(k) referenced by <a href="mailto:test@nil.local" class="email">test@nil.local</a>')
  end

  describe "usable" do
    it "for CFR text (internal references with context)" do
      expect(
        described_class.new(
          options: {cfr: {context: {title: "7"}}}
        ).hyperlink("please refer to 1 CFR 2.7(a)(2) and chapter II of this title", default: {relative: true, class: nil, target: nil}, options: {cfr: {current: true}})
      ).to eql(
        'please refer to <a href="/current/title-1/section-2.7#p-2.7(a)(2)">1 CFR 2.7(a)(2)</a> and <a href="/current/title-7/chapter-II">chapter II of this title</a>'
      )
    end

    it "for CFR text (complete references without context)" do
      expect(
        described_class.new.hyperlink("please refer to 1 CFR 2.7(a)(2) and chapter II of this title", default: {relative: true, class: nil, target: nil}, options: {cfr: {current: true}})
      ).to eql(
        'please refer to <a href="/current/title-1/section-2.7#p-2.7(a)(2)">1 CFR 2.7(a)(2)</a> and chapter II of this title'
      )
    end

    it "for Issues" do
      expect(
        described_class.new.hyperlink("8 CFR 1208, 1209-1212, 1235 (85 FR 23904, Apr. 30, 2020)", default: {target: nil}, options: {cfr: {compare: {from: "2020-05-30", to: "2020-06-01"}, relative: true}})
      ).to eql(
        '<a href="/compare/2020-05-30/to/2020-06-01/title-8/part-1208" class="cfr external">8 CFR 1208</a>, <a href="/compare/2020-05-30/to/2020-06-01/title-8/part-1209" class="cfr external">1209-1212</a>, <a href="/compare/2020-05-30/to/2020-06-01/title-8/part-1235" class="cfr external">1235</a> (<a href="https://www.federalregister.gov/citation/85-FR-23904" class="fr-reference" data-reference="85 FR 23904">85 FR 23904</a>, Apr. 30, 2020)'
      )
    end

    it "for Issues (dotted sections)" do
      expect(
        described_class.new.hyperlink("50 CFR 17.11, 17.47 (86 FR 72427 Dec. 21, 2021)", default: {target: nil}, options: {cfr: {compare: {from: "2020-05-30", to: "2020-06-01"}, relative: true}})
      ).to eql(
        '<a href="/compare/2020-05-30/to/2020-06-01/title-50/section-17.11" class="cfr external">50 CFR 17.11</a>, <a href="/compare/2020-05-30/to/2020-06-01/title-50/section-17.47" class="cfr external">17.47</a> (<a href="https://www.federalregister.gov/citation/86-FR-72427" class="fr-reference" data-reference="86 FR 72427">86 FR 72427</a> Dec. 21, 2021)'
      )
    end

    it "for Issues (reverse ecfr/fr absolute/relative)" do
      expect(
        described_class.new.hyperlink("8 CFR 1208 (85 FR 23904, Apr. 30, 2020)", default: {target: nil}, options: {federal_register: {relative: true}, cfr: {compare: {from: "2020-05-30", to: "2020-06-01"}}})
      ).to eql(
        '<a href="https://www.ecfr.gov/compare/2020-05-30/to/2020-06-01/title-8/part-1208" class="cfr external">8 CFR 1208</a> (<a href="/citation/85-FR-23904" class="fr-reference" data-reference="85 FR 23904">85 FR 23904</a>, Apr. 30, 2020)'
      )
    end

    it "for Agency Page" do
      expect(
        described_class.new.render({cfr: {citations: [{"id" => 1, "agency_id" => 1, "title" => "1", "subtitle" => nil, "chapter" => "III"}]}}, default: {relative: true, class: "cfr-reference", target: nil}, options: {cfr: {current: true}})
      ).to eql(
        '<a href="/current/title-1/chapter-III" class="cfr-reference">1 CFR Chapter III</a>'
      )
    end

    it "provides best-guess suggestions" do
      expect(
        described_class.cfr_best_guess_hierarchy("17 CFR 240.11a1-1(T)")
      ).to eql(
        {title: "17", section: "240.11a1-1(T)"}
      )
    end

    it "allows plucking values" do
      results = []
      described_class.new.each("40 CFR 273.13, 273.33, and 273.52") do |citation|
        results << citation[:hierarchy].slice(*%i[title part subpart section])
      end

      expect(results).to eql(
        [{title: "40", section: "273.13"}, {title: "40", section: "273.33"}, {title: "40", section: "273.52"}]
      )
    end

    it "allows simple transformation" do
      x = 0
      expect(
        described_class.new.each("Lorem ipsum dolor 42 CFR 273 sit amet, consectetur 40 CFR 273.13, 273.33, and 273.52 adipiscing elit.") do |citation|
          citation[:link] = "(link_#{citation.dig(:hierarchy, :title)}_#{x += 1})"
        end
      ).to eql(
        "Lorem ipsum dolor (link_42_1) sit amet, consectetur (link_40_2), (link_40_3), and (link_40_4) adipiscing elit."
      )
    end
  end

  it "doesn't mutate context" do
    text = "please see part 300 of this title. §§ 111.111(a), (b); and 111.333(c)"

    original = {title: "1", part: "100"}
    context = original.dup

    described_class.new(options: {cfr: {context: context}}).hyperlink(text, default: {relative: true, class: nil, target: nil}, options: {cfr: {on: "2020-01-01"}})

    expect(context).to eq original
  end
end
