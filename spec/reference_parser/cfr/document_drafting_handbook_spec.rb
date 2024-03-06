require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper
  describe "per Document Drafting Handbook" do # Document Drafting Handbook
    [
      "DDH table 2-7 (p68/2-50)", [
        {ex: "1 CFR chapter I", citation: {title: "1", chapter: "I"}, expected_url: "/current/title-1/chapter-I"},
        {ex: "1 CFR part 2", citation: {title: "1", chapter: "I", part: "2"}, optional: [:chapter], expected_url: "/current/title-1/part-2"},
        {ex: "1 CFR 2.7", citation: {title: "1", chapter: "I", part: "2", section: "2.7"}, optional: [:chapter, :part], expected_url: "/current/title-1/section-2.7"},
        {ex: "1 CFR 2.7(a)(2)", citation: {title: "1", chapter: "I", part: "2", section: "2.7", paragraph: "(a)(2)"}, optional: [:chapter, :part], expected_url: "/current/title-1/section-2.7#p-2.7(a)(2)"}
      ],
      "DDH table 2-8 (p68/2-50)", [
        {ex: "chapter II of this title", citation: {title: "1", chapter: "II"}, context: {title: "1", chapter: "I"}, context_specific: true},
        {ex: "part 300 of this title", citation: {title: "1", chapter: "I", part: "300"}, context: {title: "1", chapter: "I", part: "100"}, context_specific: true},
        {ex: "§ 300.19 of this title", citation: {title: "1", chapter: "I", section: "300.19"}, optional: [:chapter], context: {title: "1", chapter: "I", section: "250.10"}, context_specific: true},
        {ex: "part 30 of this chapter", citation: {title: "1", chapter: "I", part: "30"}, context: {title: "1", chapter: "I", part: "20"}, context_specific: true},
        {ex: "part 30, subpart A of this chapter", citation: {title: "1", chapter: "I", part: "30", subpart: "A"}, context: {title: "1", chapter: "I", section: "20.10"}, context_specific: true},
        {ex: "§ 30.19 of this chapter", citation: {title: "1", chapter: "I", section: "30.19"}, context: {title: "1", chapter: "I", section: "20.10"}, context_specific: true, expected_url: "/current/title-1/section-30.19"}
      ],
      "DDH table 2-9 (p69/2-51)", [
        {ex: "subpart A of this part", citation: {title: "1", part: "20", subpart: "A"}, context: {title: "1", part: "20", section: "20.5"},
         expected_url: "/current/title-1/part-20/subpart-A", context_specific: true},
        {ex: "§ 20.15", citation: {title: "1", section: "20.15"}, context: {title: "1", section: "20.5"}, context_specific: true},
        {ex: "§ 20.15(a)", citation: {title: "1", section: "20.15", paragraph: "(a)"}, context: {title: "1", section: "20.5"}, context_specific: true},
        {ex: "Appendix A of this part", citation: {title: "1", part: "20", appendix: "A"}, context: {title: "1", part: "20", section: "20.5"}, context_specific: true}
      ],
      "DDH table 2-10 (p69/2-51)", [
        {ex: "paragraph (b) of this section", text: "paragraph (b)", citation: {title: "1", section: "1", paragraph: "(b)"}, context: {title: "1", section: "1", paragraph: "(a)"}, context_specific: true},
        {ex: "paragraph (b)(1) of this section", text: "paragraph (b)(1)", citation: {title: "1", section: "1", paragraph: "(b)(1)"}, context: {title: "1", section: "1", paragraph: "(a)"}, context_specific: true},
        {ex: "paragraph (a)(2) of this section", text: "paragraph (a)(2)", citation: {title: "1", section: "1", paragraph: "(a)(2)"}, context: {title: "1", section: "1", paragraph: "(a)(1)"}, context_specific: true},
        {ex: "paragraph (a)(1)(ii) of this section", text: "paragraph (a)(1)(ii)", citation: {title: "1", section: "1", paragraph: "(a)(1)(ii)"}, context: {title: "1", section: "1", paragraph: "(a)(1)(ii)"}, context_specific: true},
        {ex: "this paragraph (a)", text: "paragraph (a)", citation: {title: "1", section: "1", paragraph: "(a)"}, context: {title: "1", section: "1", paragraph: "(a)"}, context_specific: true}
      ],
      "DDH table 2-7 (p68/2-50) (damaged)", [
        {ex: "1CFRchapterI", citation: {title: "1", chapter: "I"}},
        {ex: "1CFRpart2", citation: {title: "1", chapter: "I", part: "2"}, optional: [:chapter]},
        {ex: "1CFR2.7", citation: {title: "1", chapter: "I", part: "2", section: "2.7"}, optional: [:chapter, :part]},
        {ex: "1CFR2.7(a)(2)", citation: {title: "1", chapter: "I", part: "2", section: "2.7", paragraph: "(a)(2)"}, optional: [:chapter, :part]}
      ]
    ].each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end
  end
end
