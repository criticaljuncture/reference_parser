require "spec_helper"

STAT_SCENARIOS = [
  {ex: "23 Stat. 58, 118, sec. 7", citations: [{volume: 23, chapter: 58}, {volume: 23, chapter: 188}]},
  {ex: "40 Stat. 220;", text: "40 Stat. 220", citation: {volume: 40, chapter: 220}},
  {ex: ", 73 Stat. 4, ", text: "73 Stat. 4", citation: {volume: 73, chapter: 4}},
  {ex: "94 Stat. 1111-1114", text: "94 Stat. 1111-1114", citation: {volume: 94, chapter: "1111-1114"}},
  {ex: "Sec. 602, 78 Stat. 252; 4", text: "78 Stat. 252", citation: {volume: 78, chapter: "252"}},
  {ex: "Sec. 8013, 100 Stat. 1053, as amended;", text: "100 Stat. 1053", citation: {volume: 100, chapter: "1053"}}
]

RSpec.describe ReferenceParser::Stat do
  describe "optionally identifies United States Statutes at Large" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :stat).hyperlink(
          "Lorem ipsum dolor sit amet, 12 Stat. 345 consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">12 Stat. 345</a> consectetur adipiscing elit.'
    end

    STAT_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :stat).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: "#"})
        end
      end
    end
  end
end
