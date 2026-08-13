require "spec_helper"

SEGMENT_OPTIONS = {cfr: {best_guess: true, allow_aliases: true, prefer_part: true, implied_title: true, context: {title: "43"}}}

SEGMENT_EXAMPLES = [
  "Subparts 2804, 2884",
  "Part 3832; Subpart B",
  "§2801.5 & §2804.10",
  "Subchapter A, Group 1700",
  "Group 9100",
  "",
  "See 43 CFR part 4, and part 1780."
]

RSpec.describe "ReferenceParser#segments" do # rubocop:disable RSpec/DescribeClass
  let(:parser) { reference_parser_for(only: :cfr, options: SEGMENT_OPTIONS) }

  SEGMENT_EXAMPLES.each do |example|
    it "does not damage (#{example.inspect})" do
      expect(parser.segments(example).map { |segment| segment[:text] }.join).to eq(example)
    end
  end

  it "splits text segments on citation boundaries" do
    expect(parser.segments("Subparts 2804, 2884").map { |segment| [segment[:text], segment.key?(:citation)] })
      .to eq([["Subparts 2804", true], [", ", false], ["2884", true]])
  end

  it "includes citation details" do
    expect(parser.segments("Subparts 2804, 2884").filter_map { |segment| segment.dig(:citation, :hierarchy) })
      .to eq([{title: "43", subpart: "2804"}, {title: "43", subpart: "2884"}])
  end

  it "does not damage unrecognized text" do
    expect(parser.segments("Group 9100")).to eq([{text: "Group 9100"}])
  end
end
