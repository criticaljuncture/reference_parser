require "spec_helper"

STAT_SCENARIOS = [
  {ex: "23 Stat. 58, 118, sec. 7", text: "23 Stat. 58", citations: [{volume: 23, chapter: 58}, {volume: 23, chapter: 118}]},
  {ex: "40 Stat. 220;", text: "40 Stat. 220", citation: {volume: 40, chapter: 220}},
  {ex: ", 73 Stat. 4, ", text: "73 Stat. 4", citation: {volume: 73, chapter: 4}},
  {ex: "94 Stat. 1111-1114", text: "94 Stat. 1111-1114", citation: {volume: 94, chapter: "1111-1114"}},
  {ex: "Sec. 602, 78 Stat. 252; 4", text: "78 Stat. 252", citation: {volume: 78, chapter: "252"}},
  {ex: "Sec. 8013, 100 Stat. 1053, as amended;", text: "100 Stat. 1053", citation: {volume: 100, chapter: "1053"}},
  {ex: "68A Stat. 580;", text: "68A Stat. 580", citation: {volume: "68A", chapter: "580"}},
  {ex: "38 Stat. 719 as amended, 721", text: "38 Stat. 719", citations: [{volume: 38, chapter: 719}, {volume: 38, chapter: 721}]},
  {ex: "92 Stat. 865 et seq.;", text: "92 Stat. 865 et seq.", citation: {volume: 92, chapter: "865 et seq"}},
  {ex: "113 Stat. 1501a, 16 U.S.C. 528 note;", text: "113 Stat. 1501a", citation: {volume: 113, chapter: "1501a"}},
  {ex: "58 Stat. 691, as amended, 707, secs. 412", text: "58 Stat. 691", citations: [{volume: 58, chapter: 691}, {volume: 58, chapter: 707}]},
  {ex: "77 Stat. 394, secs. 394, 395", text: "77 Stat. 394", citations: [{volume: 77, chapter: 394}, {volume: 77, chapter: 395}]},
  {ex: "124. Stat. 2282;", text: "124. Stat. 2282", citation: {volume: 124, chapter: 2282}},
  {ex: "Secs. 4, 5, 303, 48 Stat., as amended, 1066, 1068, 1082;", text: "48 Stat. 1066", citations: [{volume: 48, chapter: 1066}, {volume: 48, chapter: 1068}, {volume: 48, chapter: 1082}]}
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
