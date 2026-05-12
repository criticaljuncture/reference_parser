require "spec_helper"

NOTICE_SCENARIOS = [
  {ex: "; Notice of November 7, 2024, ", text: "Notice of November 7, 2024", citation: {date: "2024-11-07"}},
  {ex: "Notice of August 14, 2023", citation: {date: "2023-08-14"}}
]

RSpec.describe ReferenceParser::Notice do
  describe "optionally identifies Presidential Documents: Notices" do
    let(:reference_parser) { ReferenceParser.new(only: :notice) }

    it "example usage" do
      expect(
        ReferenceParser.new(only: :notice).hyperlink(
          "Lorem ipsum dolor sit amet; Notice of November 7, 2024, consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet; <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Notice of November 7, 2024</a>, consectetur adipiscing elit.'
    end

    NOTICE_SCENARIOS.each do |scenario|
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
