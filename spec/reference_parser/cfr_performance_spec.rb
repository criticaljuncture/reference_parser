require "spec_helper"

SCENERIOS_CFR_PERFORMANCE = [
  "expanded preable local list of paragraphs", [
    {ex: '<span class="paragraph-hierarchy"><span class="paren">(</span>A<span class="paren">)</span></span> OEPA Ohio Administrative Code (OAC) Rule 3745-21-01, Definitions, Paragraphs (B)(1), (B)(2), (B)(6), (D)(6), (D)(8), (D)(22), (D)(45), (D)(48), (D)(58), (M)(8); effective January 17, 1995. </p></div>
      <div id="p-52.1894(c)(103)(i)(B)"><p class="indent-4" data-title="52.1894(c)(103)(i)(B)"><span class="paragraph-hierarchy"><span class="paren">(</span>B<span class="paren">)</span></span> OEPA OAC Rule 3745-21-04, Attainment Dates and Compliance Time Schedules, Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b) and (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c), and (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65); effective January 17, 1995. </p></div>
      <div id="p-52.1894(c)(103)(i)(C)"><p class="indent-4" data-title="52.1894(c)(103)(i)(C)">'},
    {ex: "Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b) and (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c), and (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65)"},
    {ex: "Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b), (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c),  (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65)"}
  ]
]

RSpec.describe ReferenceParser::Cfr do
  describe "perf triggering fragments" do
    SCENERIOS_CFR_PERFORMANCE.each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].truncate(24)}" do
            expect {
              ReferenceParser.new.hyperlink(example[:ex])
            }.not_to raise_error
          end
        end
      end
    end
  end
end
