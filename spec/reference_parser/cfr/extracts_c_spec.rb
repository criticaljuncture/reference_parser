require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "extracts" do
    [
      "extracts (30+)", [

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
         ]}
      ]
    ].each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].to_s.truncate(24)}" do
            test_cfr_scenerio(example)
          end
        end
      end
    end
  end
end
