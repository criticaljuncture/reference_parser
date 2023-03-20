require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper
  describe "observed citation formats" do
    [
      "bluebook", [
        {ex: "12 C.F.R. pt. 220", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "12", part: "220"}, expected_url: "/current/title-12/part-220"},
        {ex: "12 C.F.R. pt. 220", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "12", part: "220"}, optional: [:chapter], expected_url: "/current/title-12/part-220",
         with_surrounding_text: "12 C.F.R. pt. 220 (2014)"}
      ],
      "title-specific usage", [
        # (#42) Title 48 subsections
        {ex: "paragraph (b)", context: {composite_hierarchy: "48::1:C:15:15.4:15.404-1"},
         citation: {title: "48", section: "15.404-1", paragraph: "(b)"},
         with_surrounding_text: "see paragraph (b) of this subsection"},

        {ex: "subparagraph (b)(2)", context: {composite_hierarchy: "48::1:A:1:1.6:1.602-3"},
         citation: {title: "48", section: "1.602-3", paragraph: "(b)(2)"},
         with_surrounding_text: "authority in subparagraph (b)(2) of this subsection may be"},

        {ex: "paragraphs (a)(2) and (a)(3)", context: {composite_hierarchy: "48::9:I:970:970.31:970.3102-05-46"},
         citations: [
           {title: "48", section: "970.3102-05-46", paragraph: "(a)(2)"},
           {title: "48", section: "970.3102-05-46", paragraph: "(a)(3)"}
         ],
         with_surrounding_text: "compliance with paragraphs (a)(2) and (a)(3) of this subsection may"},

        {ex: "included in the other paragraphs of this section", citation: :expect_none, html_appearance: :expect_none, context: {title: "2", part: "200", appendix: "Appendix I to Part 200"}}

      ]
    ].each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].to_s.truncate(24)}" do
            expect_passing_cfr_scenerio(example)
          end
        end
      end
    end
  end
end
