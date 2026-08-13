require "spec_helper"

IMPLIED_TITLE_SCENARIOS = [
  {ex: "43 CFR Subparts 2804, 2884", citations: [{title: "43", subpart: "2804"}, {title: "43", subpart: "2884"}]},
  {ex: "§2568.70 et seq.", text: "§2568.70 et seq.", citations: [{title: "43", section: "2568.70"}]},
  {ex: "§2804.10, subpart 2884", citations: [{title: "43", section: "2804.10"}, {title: "43", subpart: "2884"}]},

  {ex: "§3453.2-4, subpart 3474", citations: [{title: "43", section: "3453.2-4"}, {title: "43", subpart: "3474"}]},

  {ex: "§3503.14, Subpart 3504", citations: [{title: "43", section: "3503.14"}, {title: "43", subpart: "3504"}]},
  {ex: "§8365", citations: [{title: "43", section: "8365"}]},
  {ex: "Chapter II", citations: [{title: "43", chapter: "II"}], urls: ["/current/title-43/chapter-II"]},
  {ex: "Group 9100", citations: []},
  {ex: "Part 123, subpart C, 123.51", citations: [{title: "43", part: "123", subpart: "C"}]},
  {ex: "Part 171, subpart B-D", citations: [{title: "43", part: "171", subpart: "B-D"}]},
  {ex: "Part 171, subpart C, Part 172, subpart C", citations: [{title: "43", part: "171", subpart: "C"}, {title: "43", part: "172", subpart: "C"}], urls: ["/current/title-43/part-171/subpart-C", "/current/title-43/part-172/subpart-C"]},
  {ex: "Part 2930", citations: [{title: "43", part: "2930"}], urls: ["/current/title-43/part-2930"]},
  {ex: "Part 3400 et seq.", text: "Part 3400 et seq.", citations: [{title: "43", part: "3400"}]},
  {ex: "Part 3832; Subpart B", citations: [{title: "43", part: "3832"}, {title: "43", subpart: "B"}]},
  {ex: "Part2930", citations: []},
  {ex: "Parts 1810-1880", citations: [{title: "43", part: "1810", part_end: "1880"}]},
  {ex: "Parts 2800, 2880", citations: [{title: "43", part: "2800"}, {title: "43", part: "2880"}]},
  {ex: "Parts 3500 through 3590", citations: [{title: "43", part: "3500"}, {title: "43", part: "3590"}]},
  {ex: "Subchapter A, Group 1700", citations: [{title: "43", subchapter: "A"}]},
  {ex: "Subchapter D (4000)", citations: [{title: "43", subchapter: "D"}]},
  {ex: "Subchapter H", citations: [{title: "43", subchapter: "H"}], urls: ["/current/title-43/subchapter-H"]},
  {ex: "subchapter of this part", citations: []},
  {ex: "Subpart 3504", citations: [{title: "43", subpart: "3504"}], urls: ["/current/title-43/subpart-3504"]},
  {ex: "subpart of the rule", citations: []},
  {ex: "Subparts 1850, 3713, 3872", citations: [{title: "43", subpart: "1850"}, {title: "43", subpart: "3713"}, {title: "43", subpart: "3872"}]},
  {ex: "Subparts 2804, 2884", citations: [{title: "43", subpart: "2804"}, {title: "43", subpart: "2884"}], urls: ["/current/title-43/subpart-2804", "/current/title-43/subpart-2884"]},
  {ex: "Subparts 2931 and 2932", citations: [{title: "43", subpart: "2931"}, {title: "43", subpart: "2932"}]},
  {ex: "Subparts 3214-3215", citations: [{title: "43", subpart: "3214-3215"}]},
  {ex: "Subtitle A, part 2, subpart E", citations: [{title: "43", subtitle: "A", part: "2", subpart: "E"}], urls: ["/current/title-43/part-2/subpart-E"]},
  {ex: "Subtitle A, part 8", citations: [{title: "43", subtitle: "A", part: "8"}], urls: ["/current/title-43/part-8"]},
  {ex: "Subtitle of the Act", citations: []}
]

RSpec.describe "ReferenceParser::Cfr implied title" do # rubocop:disable RSpec/DescribeClass
  def hierarchies_for(parser, text)
    [].tap { |results| parser.each(text) { |citation| results << citation[:hierarchy] } }
  end

  describe "implied title" do
    IMPLIED_TITLE_SCENARIOS.each do |scenario|
      describe scenario[:ex] do
        let(:parser) { reference_parser_for(only: :cfr, options: {cfr: {best_guess: true, allow_aliases: true, prefer_part: true, implied_title: true, context: {title: "43"}}}) }

        it scenario[:ex] do
          expect(hierarchies_for(parser, scenario[:ex])).to eq(scenario[:citations])

          html = parser.hyperlink(scenario[:ex], default: {target: nil, class: nil})
          doc = Nokogiri::HTML.parse(html)
          expect(doc.text).to eq(Nokogiri::HTML.parse(scenario[:ex]).text)

          if (text = scenario[:text]).present?
            expect(html).to include(text)
          end

          (scenario[:urls] || []).each do |url|
            expect(html).to include(url)
          end
        end
      end
    end
  end
end
