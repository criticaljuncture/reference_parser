require "spec_helper"

PROC_SCENARIOS = [
  {ex: "Lorem ipsum dolor sit amet, Proc. 10414 consectetur adipiscing elit.", text: "Proc. 10414", citation: {proclamation_number: 10414}},
  {ex: ["Proc. 10414",
    "Proclamation 10414",
    "Proclamation No. 10414",
    "Proclamation No 10414",
    "Presidential Proclamation 10414",
    "Proclamation No. 10,414"], citation: {proclamation_number: 10414}},
  {ex: "Proc. No. 3004 of January 17, 1953", citation: {proclamation_number: 3004, date: "1953-01-17"}},
  {ex: "Proclamation No. 6780 of March 23, 1995", citation: {proclamation_number: 6780, date: "1995-03-23"}}
]

RSpec.describe ReferenceParser::Proclamation do
  describe "links Proclamations" do
    let(:reference_parser) { ReferenceParser.new(only: :proclamation, options: {include_unlinked: true}) }

    it "captures proclamation_number" do
      citations = []
      reference_parser.each("Proc. 10414") do |citation, slug|
        citations << citation
      end
      expect(citations.map { it[:proclamation_number] }).to eq([10414])
    end

    it "example usage" do
      expect(
        reference_parser.hyperlink(
          "Lorem ipsum dolor sit amet, Proc. 10414 consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Proc. 10414</a> consectetur adipiscing elit.'
    end

    PROC_SCENARIOS.each do |scenario|
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
  end
end
