require "spec_helper"

REORGANIZATION_PLAN_SCENARIOS = [
  {ex: "; 1946 Reorganization Plan No. 2, sec. 3,", text: "1946 Reorganization Plan No. 2", citation: {year: "1946", plan_number: "2"}},
  {ex: "; Reorganization Plan No. 19 of 1950, sec. 1,", text: "Reorganization Plan No. 19 of 1950", citation: {year: "1950", plan_number: "19"}},
  {ex: "1946 Reorganization Plan No 2", citation: {year: "1946", plan_number: "2"}},
  {ex: "Reorganization Plan No 19 of 1950", citation: {year: "1950", plan_number: "19"}},
  {ex: "1946 Reorganization Plan No. 2", citation: {year: "1946", plan_number: "2"}},
  {ex: "Reorg. Plan No. 14 of 1950, 64 Stat. 1267", citation: {year: "1950", plan_number: "14"}},
  {ex: "Reorganization Plans No. 21 of 1950 (64 Stat. 1273), and No. 7 of 1961 (75 Stat. 840)", citations: [{year: "1950", plan_number: "21"}, {year: "1961", plan_number: "7"}]},
  {ex: "Reorganization Plan Number 6 of 1950.", citation: {year: "1950", plan_number: "6"}},
  {ex: "Reorganization Plan No. 3, of 1970.", citation: {year: "1970", plan_number: "3"}},
  {ex: "Reorgan. Plan No. 1 of 1978", citation: {year: "1978", plan_number: "1"}},
  {ex: "Reorganization Plan No. 3 (3 CFR, 1978 Comp., p. 329);", citation: {year: "1978", plan_number: "3"}}
]

RSpec.describe ReferenceParser::ReorganizationPlan do
  describe "optionally links Reorganization Plans" do
    let(:reference_parser) { ReferenceParser.new(only: :reorganization_plan, options: {include_unlinked: true}) }

    it "example usage" do
      expect(
        reference_parser.hyperlink(
          "; 1946 Reorganization Plan No. 2, sec. 3,",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql '; <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">1946 Reorganization Plan No. 2</a>, sec. 3,'
    end

    REORGANIZATION_PLAN_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          found = []
          reference_parser.each(example) do |citation, slug|
            found << citation
          end
          expected_citations = [scenario[:citation], scenario[:citations]].flatten.compact
          expect(
            found.map { |citation| citation.slice(*expected_citations.first.keys) }
          ).to eq(expected_citations)
        end
      end
    end

    def reorganization_plan_url(options)
      ReferenceParser::ReorganizationPlan.new({}).url(options)
    end
  end
end
