require "spec_helper"

PL_SCENARIOS = [
  {ex: "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.", text: "Public Law 117-9", citation: {congress: 117, law: 9}},
  {ex: "(Pub. L. 107-295)", text: "Pub. L. 107-295", citation: {congress: 107, law: 295}},

  {ex: ["Public Law 107-295",
    "Pub. Law 107-295",
    "Pub. L. 107-295",
    "P.L. 107-295"], citation: {congress: 107, law: 295}},

  {ex: ["Public Law 104–208",
    "Pub. Law 104–208",
    "Pub. L. 104–208",
    "P.L. 104–208",
    "Pub. L. No. 104-208"], citation: {congress: 104, law: 208}},

  # false positives
  {ex: "phone number 202-693-0126 or e-mailed", citation: :expect_none},

  {ex: ["Public Law 114-1"], citation: {congress: 114, law: 1}},
  {ex: ["Public Law 114-329"], citation: {congress: 114, law: 329}},

  # suppress implausible
  {ex: ["Public Law 114-0",
    "Public Law 114-330",
    "Public Law 114-357",
    "Public Law 104-334",
    "Public Law 118-275"], citation: :expect_none},

  # authority tracking (include un-linkable historical)
  {ex: "Pub. L. No. 103-267", citation: {congress: 103, law: "267"}, include_unlinked: true},

  # list formats
  {ex: "10 U.S.C. 113, and Public Laws 106-65, 108-375, 109-163, 109-364, 110-417, 111-84, 111-383, 112-81, 112-239, 113-291, 113-66,113-291, and 114-92.",
   citations: [
     {congress: 106, law: "65"},
     {congress: 108, law: "375"},
     {congress: 109, law: "163"},
     {congress: 109, law: "364"},
     {congress: 110, law: "417"},
     {congress: 111, law: "84"},
     {congress: 111, law: "383"},
     {congress: 112, law: "81"},
     {congress: 112, law: "239"},
     {congress: 113, law: "291"},
     {congress: 113, law: "66"},
     {congress: 113, law: "291"},
     {congress: 114, law: "92"}
   ], include_unlinked: true},
  {ex: "Public Law 11-8 and 111-317;", citations: [{congress: 11, law: "8"}, {congress: 111, law: "317"}], include_unlinked: true},
  {ex: "Pub. L. 89-564; 89-670; 91-605; and 93-87.", citations: [{congress: 89, law: "564"}, {congress: 89, law: "670"}, {congress: 91, law: "605"}, {congress: 93, law: "87"}], include_unlinked: true}

]

RSpec.describe ReferenceParser::PublicLaw do
  describe "links Public Law" do
    let(:reference_parser) { ReferenceParser.new(only: :public_law) }
    let(:reference_parser_with_unlinked) { ReferenceParser.new(only: :public_law, options: {include_unlinked: true}) }

    it "example usage" do
      expect(
        reference_parser.hyperlink(
          "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.govinfo.gov/link/plaw/117/public/9">Public Law 117-9</a> consectetur adipiscing elit.'
    end

    PL_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:include_unlinked]
            found = []
            reference_parser_with_unlinked.each(example) do |citation, slug|
              found << citation
            end
            expected_citations = [scenario[:citation], scenario[:citations]].flatten.compact
            expect(
              found.map { |citation| citation.slice(*expected_citations.first.keys) }
            ).to eq(expected_citations)
          elsif scenario[:citation] == :expect_none
            expect(
                reference_parser.hyperlink(example, default: {target: nil, class: nil})
              ).not_to have_tag("a")
          else
            expect(
              reference_parser.hyperlink(example, default: {target: nil, class: nil})
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: public_law_url(scenario[:citation])})
          end
        end
      end
    end

    def public_law_url(options)
      ReferenceParser::PublicLaw.new({}).url(options)
    end
  end
end
