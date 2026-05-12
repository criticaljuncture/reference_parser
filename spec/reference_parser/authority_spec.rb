require "spec_helper"

AUTHORITY_SCENARIOS = [
  {expect: "STAT 78/252, USC 42/2000d-1", ex: "Sec. 602, 78 Stat. 252; 42 U.S.C. 2000d-1; sec. 15.9(d) of subpart A to 7 CFR, part 15, and laws referred to in the appendix to subpart A, part 15, title 7 CFR."},
  {expect: "PUBL 110/53, STAT 121/266", ex: "; Pub. L. 110-53 (121 Stat. 266, Aug. 3, 2007)."},
  {expect: "USC 30/901 et seq", ex: "30 U.S.C. 901 et seq."},
  {expect: "USC 5/552a, USC 5/552 note", ex: "5 U.S.C. 552a and 552 note"}
]

RSpec.describe "ReferenceParser.new(only: :authorities)" do # rubocop:disable RSpec/DescribeClass
  describe "overlapping authority patterns" do
    let(:reference_parser) { ReferenceParser.new(only: :authorities) }

    AUTHORITY_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          references = []
          reference_parser.each(example) do |reference, source|
            hierarchy = reference[:hierarchy] || reference
            a = hierarchy.values_at(*%i[title congress volume]).compact.join(" ")
            b = (hierarchy.values_at(*%i[part section law chapter]) + reference.values_at(*%i[trailing_modifier])).compact.join(" ")
            c = reference.values_at(*%i[date]).compact.join(" ")
            references << "#{source.to_s.upcase} #{[a, b, c].select(&:present?).join("/")}"
          end
          expect(references).to eq(scenario[:expect].split(",").map(&:strip))
        end
      end
    end
  end
end
