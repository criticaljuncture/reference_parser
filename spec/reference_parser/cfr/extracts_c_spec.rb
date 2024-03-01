require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "extracts" do
    [
      "(30+)", [

        # #31 /current/title-49/subtitle-B/chapter-I/subchapter-D/part-192/subpart-A/section-192.7#p-192.7(j)(1)
        {ex: "192.712(b)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"}, citation: :expect_none},

        # #32 /current/title-49/subtitle-B/chapter-I/subchapter-D/part-192/subpart-A/section-192.7#p-192.7(j)(1)
        {ex: "§§ 192.485(c); 192.632(a); 192.712(b); 192.933(a) and (d)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         with_surrounding_text: "approved for §§ 192.485(c); 192.632(a); 192.712(b); 192.933(a) and (d).",
         citations: [
           {title: "49", section: "192.485", paragraph: "(c)"},
           {title: "49", section: "192.632", paragraph: "(a)"},
           {title: "49", section: "192.712", paragraph: "(b)"},
           {title: "49", section: "192.933", paragraph: "(a)"},
           {title: "49", section: "192.933", paragraph: "(d)"}
         ]},

        {ex: "§§ 192.153(a), (b), (d); and 192.165(b)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         citations: [
           {title: "49", section: "192.153", paragraph: "(a)", expected_url: "/current/title-49/section-192.153#p-192.153(a)"},
           {title: "49", section: "192.153", paragraph: "(b)", expected_url: "/current/title-49/section-192.153#p-192.153(b)"},
           {title: "49", section: "192.153", paragraph: "(d)", expected_url: "/current/title-49/section-192.153#p-192.153(d)"},
           {title: "49", section: "192.165", paragraph: "(b)", expected_url: "/current/title-49/section-192.165#p-192.165(b)"}
         ]},

        {ex: "§§ 192.153(a), (b), (d); and 192.165(b)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         citations: [
           {title: "49", section: "192.153", paragraph: "(a)", expected_url: "/current/title-49/section-192.153#p-192.153(a)"},
           {title: "49", section: "192.153", paragraph: "(b)", expected_url: "/current/title-49/section-192.153#p-192.153(b)"},
           {title: "49", section: "192.153", paragraph: "(d)", expected_url: "/current/title-49/section-192.153#p-192.153(d)"},
           {title: "49", section: "192.165", paragraph: "(b)", expected_url: "/current/title-49/section-192.165#p-192.165(b)"}
         ],
         repeat_reference: 3},

        {ex: "§§ 192.111(a), (b); and 192.333(c)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         citations: [
           {title: "49", section: "192.111", paragraph: "(a)", expected_url: "/current/title-49/section-192.111#p-192.111(a)"},
           {title: "49", section: "192.111", paragraph: "(b)", expected_url: "/current/title-49/section-192.111#p-192.111(b)"},
           {title: "49", section: "192.333", paragraph: "(c)", expected_url: "/current/title-49/section-192.333#p-192.333(c)"}
         ]},

        {ex: "§§ 192.444(d); 192.555(e)", context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         citations: [
           {title: "49", section: "192.444", paragraph: "(d)", expected_url: "/current/title-49/section-192.444#p-192.444(d)"},
           {title: "49", section: "192.555", paragraph: "(e)", expected_url: "/current/title-49/section-192.555#p-192.555(e)"}
         ]},

        {ex: ["§§ 192.111(a), (b); and 192.333(c)", "§§ 192.444(d); 192.555(e);"], context: {composite_hierarchy: "49:B:I:D:192:A:192.7"},
         with_surrounding_text: "...lorem ipsum dolor §§ 192.111(a), (b); and 192.333(c). consectetuer adipiscing elit. Vivamus §§ 192.444(d); 192.555(e); vitae risus vitae...",
         citations: [
           {title: "49", section: "192.111", paragraph: "(a)", expected_url: "/current/title-49/section-192.111#p-192.111(a)"},
           {title: "49", section: "192.111", paragraph: "(b)", expected_url: "/current/title-49/section-192.111#p-192.111(b)"},
           {title: "49", section: "192.333", paragraph: "(c)", expected_url: "/current/title-49/section-192.333#p-192.333(c)"},
           {title: "49", section: "192.444", paragraph: "(d)", expected_url: "/current/title-49/section-192.444#p-192.444(d)"},
           {title: "49", section: "192.555", paragraph: "(e)", expected_url: "/current/title-49/section-192.555#p-192.555(e)"}
         ]},

        # #33 /current/title-49/subtitle-B/chapter-I/subchapter-D/part-193/subpart-I
        {ex: "Each operator must provide and maintain fire protection at LNG plants according to sections 9.1 through 9.7 and section 9.9 of NFPA-59A-2001", citation: :expect_none, html_appearance: :expect_none, context: {title: "49", section: "193.2801"}},

        # #34 /current/title-21/chapter-I/subchapter-B/part-101/subpart-A/section-101.2#p-101.2(b)
        {ex: "§§ 101.4, 101.5, 101.8, 101.9, 101.13, 101.17, 101.36", context: {composite_hierarchy: "21::I:B:101:A:101.2"},
         citations: [
           {title: "21", section: "101.4", expected_url: "/current/title-21/section-101.4"},
           {title: "21", section: "101.5", expected_url: "/current/title-21/section-101.5"},
           {title: "21", section: "101.8", expected_url: "/current/title-21/section-101.8"},
           {title: "21", section: "101.9", expected_url: "/current/title-21/section-101.9"},
           {title: "21", section: "101.13", expected_url: "/current/title-21/section-101.13"},
           {title: "21", section: "101.17", expected_url: "/current/title-21/section-101.17"},
           {title: "21", section: "101.36", expected_url: "/current/title-21/section-101.36"}
         ]},

        {ex: "subpart D of part 101, and part 105 of this chapter", context: {composite_hierarchy: "21::I:B:101:A:101.2"},
         citations: [
           {title: "21", chapter: "I", part: "101", subpart: "D", expected_url: "/current/title-21/part-101/subpart-D"},
           {title: "21", chapter: "I", part: "105", expected_url: "/current/title-21/part-105"}
         ]},

        # 10:430:Appendix M1 to Subpart B of Part 430 /current/title-10/chapter-II/subchapter-D/part-430/subpart-B/appendix-Appendix%20M1%20to%20Subpart%20B%20of%20Part%20430
        {ex: "refer to section 6.2 of AHRI 1230-2010", context: {composite_hierarchy: "10::II:D:430:B:Appendix M1 to Subpart B of Part 430"},
         citation: :expect_none},

        {ex: "requirements of section 2.5.7 of this appendix", context: {composite_hierarchy: "10::II:D:430:B:Appendix M1 to Subpart B of Part 430"},
         citation: :expect_none}, # p-Appendix-M1-to-Subpart-B-of-Part-430(2.5.7)

        {ex: "from this appendix, the section 3.3 and 3.5.1 default values", context: {composite_hierarchy: "10::II:D:430:B:Appendix M1 to Subpart B of Part 430"},
         citation: :expect_none}, # p-Appendix-M1-to-Subpart-B-of-Part-430(3.3) p-Appendix-M1-to-Subpart-B-of-Part-430(3.5.1)

        {ex: "When performing section 3.5 and/or 3.8 cyclic tests", context: {composite_hierarchy: "10::II:D:430:B:Appendix M1 to Subpart B of Part 430"},
         citation: :expect_none}, # p-Appendix-M1-to-Subpart-B-of-Part-430(3.5) p-Appendix-M1-to-Subpart-B-of-Part-430(3.8)

        # /current/title-32/subtitle-B/chapter-XX/part-2001/subpart-B/section-2001.10
        {ex: "Section 1.1(a) of the Order specifies the conditions that must be met when making classification decisions. Section 1.4 specifies that information shall not be considered for", context: {composite_hierarchy: "10::II:D:430:B:Appendix M1 to Subpart B of Part 430"},
         citation: :expect_none},

        {ex: "33 CFR 165.701", citation: {title: "33", section: "165.701"}},
        {ex: "33 CFR 165.T07-0806", citation: {title: "33", section: "165.T07-0806"}},

        # #39 /current/title-10/chapter-I/part-71#p-71.5(a)
        {ex: "49 CFR part 173: subparts A, B, and I", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "173", subpart: "A"},
           {title: "49", part: "173", subpart: "B"},
           {title: "49", part: "173", subpart: "I"}
         ]},

        {ex: "49 CFR part 171: §§ 171.15 and 171.16", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "171", section: "171.15"},
           {title: "49", part: "171", section: "171.16"}
         ]},

        {ex: "49 CFR part 172: subpart H", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "172", subpart: "H"}
         ]},

        {ex: "49 CFR part 177 and parts 390 through 397", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "177"},
           {title: "49", part: "390"},
           {title: "49", part: "397"}
         ]},

        {ex: "49 CFR part 172: subpart D; and §§ 172.400 through 172.407 and §§ 172.436 through 172.441", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "172", subpart: "D", section: "172.400"},
           {title: "49", part: "172", subpart: "D", section: "172.407"},
           {title: "49", part: "172", subpart: "D", section: "172.436"},
           {title: "49", part: "172", subpart: "D", section: "172.441"}
         ]},

        {ex: "49 CFR part 172: subpart F, especially §§ 172.500 through 172.519 and 172.556; and appendices B and C", context: {composite_hierarchy: "10::I::71:A:71.5"},
         citations: [
           {title: "49", part: "172", subpart: "F", section: "172.500"},
           {title: "49", part: "172", subpart: "F", section: "172.519"},
           {title: "49", part: "172", subpart: "F", section: "172.556"},
           {title: "49", part: "172", appendix: "B"},
           {title: "49", part: "172", appendix: "C"}
         ],
         expected_hrefs: [
           "/current/title-49/part-172/appendix-Appendix%20B%20to%20Part%20172",
           "/current/title-49/part-172/appendix-Appendix%20C%20to%20Part%20172"
         ]},

        # #40 /current/title-10/chapter-I/part-71#p-71.5(a)
        {ex: "48 CFR subpart 2.1", context: {composite_hierarchy: "2:B:XI:A:1108:B:1108.340"},
         with_surrounding_text: "...by the Federal Acquisition Regulation at 48 CFR subpart 2.1, which is...",
         citation: {title: "48", subpart: "2.1", expected_url: "/current/title-48/subpart-2.1"}}, # /current/title-48/part-2/subpart-2.1 also acceptable

        # #43 /current/title-40/chapter-I/subchapter-I/part-270#270.14
        {ex: "§ 264.15(b) of this part", context: {composite_hierarchy: "40::I:I:270:B:270.14"},
         with_surrounding_text: "A copy of the general inspection schedule required by § 264.15(b) of this part.",
         citation: {title: "40", section: "264.15", paragraph: "(b)", expected_url: "/current/title-40/part-264/section-264.15#p-264.15(b)"}},

        {ex: "§§ 264.174, 264.193(i), 264.195, 264.226, 264.254, 264.273, 264.303, 264.602, 264.1033, 264.1052, 264.1053, 264.1058, 264.1084, 264.1085, 264.1086, and 264.1088 of this part",
         context: {composite_hierarchy: "40::I:I:270:B:270.14"},
         with_surrounding_text: "specific requirements in §§ 264.174, 264.193(i), 264.195, 264.226, 264.254, 264.273, 264.303, 264.602, 264.1033, 264.1052, 264.1053, 264.1058, 264.1084, 264.1085, 264.1086, and 264.1088 of this part.",
         citations: [
           {title: "40", section: "264.174"},
           {title: "40", section: "264.193", paragraph: "(i)"},
           {title: "40", section: "264.195"},
           {title: "40", section: "264.226"},
           {title: "40", section: "264.254"},
           {title: "40", section: "264.273"},
           {title: "40", section: "264.303"},
           {title: "40", section: "264.602"},
           {title: "40", section: "264.1033"},
           {title: "40", section: "264.1052"},
           {title: "40", section: "264.1053"},
           {title: "40", section: "264.1058"},
           {title: "40", section: "264.1084"},
           {title: "40", section: "264.1085"},
           {title: "40", section: "264.1086"},
           {title: "40", section: "264.1088"}
         ]},

        {ex: "paragraph (j)", context: {composite_hierarchy: "26::I:A:1::1.51-1"},
         with_surrounding_text: "(See examples 1, 2, 3, 4, 5, and 6 in paragraph (j) of this section for examples illustrating the application of the rules in this paragraph (b)(2))",
         citations: [
           {title: "26", section: "1.51-1", paragraph: "(j)", expected_url: "/current/title-26/section-1.51-1#p-1.51-1(j)"},
           {title: "26", section: "1.51-1", paragraph: "(b)(2)", expected_url: "/current/title-26/section-1.51-1#p-1.51-1(b)(2)"}
         ]},

        {ex: "5 CFR part 900, subpart F", context: {basic_hierarchy: "20::V::652:C:652.215"},
         with_surrounding_text: "described in 5 CFR part 900, subpart F—Standards for a",
         citations: [
           {title: "5", part: "900", subpart: "F", expected_url: "/current/title-5/part-900/subpart-F"}
         ]},

        # #44 /current/title-26/chapter-I/subchapter-F/part-303/section-303.1-1#p-303.1-1(b)
        {ex: "3 CFR", context: {composite_hierarchy: "26::I:F:303::303.1-1"},
         with_surrounding_text: "pursuant to Executive Order 9788 (3 CFR 1943–1948 Comp., p. 575), and",
         citation: {title: "3", expected_url: "/current/title-3"}},

        {ex: "3 CFR", context: {composite_hierarchy: "26::I:F:303::303.1-1"},
         with_surrounding_text: "pursuant to Executive Order 9788 (3 CFR 1943-1948 Comp., p. 575), and",
         citation: {title: "3", expected_url: "/current/title-3"}},

        {ex: "3 C.F.R. 298", context: {composite_hierarchy: "26::I:F:303::303.1-1"},
         with_surrounding_text: "3 C.F.R. 298 (1992 comp.)",
         citation: {title: "3", section: "298", expected_url: "/current/title-3/part-298"}},

        {ex: "3 CFR", with_surrounding_text: "3 CFR, 2019 Comp.", citation: {title: "3", expected_url: "/current/title-3"}},
        {ex: "3 CFR", with_surrounding_text: "3 CFR, 1966–1970 Comp., p. 684;", citation: {title: "3", expected_url: "/current/title-3"}}
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
