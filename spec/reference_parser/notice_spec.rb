require "spec_helper"

STAT_SCENARIOS = [
  {ex: "; Notice of November 7, 2024, ", text: "Notice of November 7, 2024", citation: {date: "2024-11-07"}}
]

RSpec.describe ReferenceParser::Notice do
  describe "optionally identifies Presidential Documents: Notices" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :notice).hyperlink(
          "Lorem ipsum dolor sit amet; Notice of November 7, 2024, consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet; <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Notice of November 7, 2024</a>, consectetur adipiscing elit.'
    end

    STAT_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :notice).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: "#"})
        end
      end
    end
  end
end
