require "spec_helper"

FR_SCENARIOS = [
  {ex: "Redesignated and amended at 53 FR 15991, 15999",
   citations: [{volume: "53", page: "15991"}, {volume: "53", page: "15999"}],
   expected_html: ['data-reference="53 FR 15991"', 'data-reference="53 FR 15999"']},

  {ex: "as amended at 43 FR 5786, Feb. 9, 1978. Redesignated and amended at 53 FR 15991, 15999, May 4, 1988; 57 FR 38146, Aug. 21, 1992;",
   citations: [{volume: "43", page: "5786"}, {volume: "53", page: "15991"}, {volume: "53", page: "15999"}, {volume: "57", page: "38146"}]},

  {ex: "website: https://www.nationalrtap.org/Technology-Tools/GTFS-Builder; and",
   citations: [{expected_href: "https://www.nationalrtap.org/Technology-Tools/GTFS-Builder"}]},

  {ex: "51 FR 6537-42", citations: [{volume: "51", page: "6537"}]},
  {ex: "59 FR 62896-62953", citations: [{volume: "59", page: "62896"}]}
]

RSpec.describe ReferenceParser::FederalRegister do
  describe "links Federal Register" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :federal_register).hyperlink(
          "Lorem ipsum dolor sit amet, 60 FR 1000 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/citation/60-FR-1000" data-reference="60 FR 1000">60 FR 1000</a> consectetur adipiscing elit.'
    end

    it "relative urls" do
      expect(
        ReferenceParser.new(only: :federal_register).hyperlink(
          "Lorem ipsum dolor sit amet, 60 FR 1000 consectetur adipiscing elit.",
          default: {target: nil, class: nil, relative: true}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="/citation/60-FR-1000" data-reference="60 FR 1000">60 FR 1000</a> consectetur adipiscing elit.'
    end

    it "does not include CFR if only FR is requested" do
      expect(
        ReferenceParser.new(only: :federal_register).hyperlink(
          "Lorem ipsum dolor sit amet, 60 FR 1000 consectetur 1 CFR 1.1 adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/citation/60-FR-1000" data-reference="60 FR 1000">60 FR 1000</a> consectetur 1 CFR 1.1 adipiscing elit.'
    end

    FR_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          result_html = ReferenceParser.new(only: [:federal_register, :url_prtpage]).hyperlink(example, default: {target: nil, class: nil})

          citations = [scenario[:citation], scenario[:citations]].flatten.compact

          if citations == 1

            expect(
              result_html
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: scenario[:expected_href] || fr_url(citation)})

          else

            citations.each do |citation|
              expect(
                result_html
              ).to have_tag("a", with: {href: citation[:expected_href] || fr_url(citation)})
            end

            expect(result_html).to have_tag("a", count: citations.count)

          end

          [scenario[:expected_html]].flatten.compact.each do |expected_html|
            expect(result_html).to include(expected_html)
          end
        end
      end
    end

    def fr_url(options)
      ReferenceParser::FederalRegister.new({}).url(options)
    end
  end
end
