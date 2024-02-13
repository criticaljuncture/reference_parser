require "spec_helper"

CFR_IDENTIFIER_SCENARIOS = [
  "subpart identifier", ReferenceParser::Cfr::SUBPART_ID, true, [
    "0", "1", "1.01", "1001.4",
    "101-25.4",
    "A", "AA", "AAA", "AAAA", "AAAAA", "AAAAAAA",
    "D-2", "D-3", "D-suspended"
  ],
  "subpart identifier", ReferenceParser::Cfr::SUBPART_ID, false, [],
  "subpart identifier (additional)", ReferenceParser::Cfr::SUBPART_ID_ADDITIONAL, true, [
    "0", "1", "1.01", "1001.4",
    "101-25.4",
    "A", "AA", "AAA", "AAAA",
    "D-2", "D-3", "D-suspended"
  ],
  "subpart identifier (additional)", ReferenceParser::Cfr::SUBPART_ID_ADDITIONAL, false, [
    "Appendix"
  ]
]

RSpec.describe ReferenceParser::Cfr do
  describe "CFR identifiers" do
    CFR_IDENTIFIER_SCENARIOS.each_slice(4) do |description, pattern, expect_match, examples|
      describe description do
        examples.each_with_index do |example, index|
          it "(#{index}) #{example.truncate(24)}" do
            if expect_match
              expect(
                /\A#{pattern}\z/ix
              ).to match(example)
            else
              expect(
                /\A#{pattern}\z/ix
              ).not_to match(example)
            end
          end
        end
      end
    end
  end
end
