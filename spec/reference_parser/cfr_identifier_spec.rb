require "spec_helper"

SCENERIOS_CFR_IDENTIFIER = [
  "subpart identifier", ReferenceParser::Cfr::SUBPART_ID, [
    "0", "1", "1.01", "1001.4", 
    "101-25.4",
    "A", "AA", "AAA", "AAAA", "AAAAA", "AAAAAAA",
    "D-2", "D-3", "D-suspended",
    "ECFR0000a00aaaaa00a",
  ],
]

RSpec.describe ReferenceParser::Cfr do
  describe "CFR identifiers" do
    SCENERIOS_CFR_IDENTIFIER.each_slice(3) do |description, pattern, examples|
      describe description do
        examples.each_with_index do |example, index|
          it "(#{index}) #{example.truncate(24)}" do
            expect(
              /\A#{pattern}\z/ix.match?(example)
            ).to be_truthy
          end
        end
      end
    end
  end
end
