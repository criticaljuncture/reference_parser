require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "extracts" do
    [
      "extracts (1-19)", [
        {ex: "40 CFR 273.13, 273.33, and 273.52",
         citations: [{title: "40", section: "273.13"}, {title: "40", section: "273.33"}, {title: "40", section: "273.52"}]},

        {ex: "§ 273.9", citation: {title: "1", section: "273.9"}, context: {title: "1"}, context_specific: true,
         with_surrounding_text: "chapter and § 273.9 will be amended"},

        {ex: "§ 173.60", citations: [{title: "49", section: "173.60"}], context: {title: "49", section: "173.1"}, context_specific: true,
         with_surrounding_text: "§ 173.60 through 1 CFR"}, # don't grab upcoming full reference

        {ex: "§§ 173.60 through 173.62", citations: [{title: "49", section: "173.60"},
          {title: "49", section: "173.62"}], context: {title: "49", section: "173.1"}, context_specific: true},

        {ex: "subpart C of part 261 of this chapter", citation: {title: "40", chapter: "I", part: "261", subpart: "C"}, context: {title: "40", chapter: "I", subchapter: "I", part: "273", subpart: "G", section: "273.81"},
         expected_url: "/current/title-40/part-261/subpart-C"}, # expanded as: /current/title-40/chapter-I/subchapter-I/part-261/subpart-C

        {ex: "36 CFR parts 1252-1258", citation: {title: "36", part: "1252", part_end: "1258"}, context: {title: "1", chapter: "I", subchapter: "A", part: "3", section: "3.3"},
         with_surrounding_text: "in the National Archives (36 CFR parts 1252-1258) govern", expected_url: "/current/title-36/part-1252"},

        {ex: "34 CFR part 256", citations: [{title: "34", part: "256", expected_url: "/current/title-34/part-256"},
          {title: "39", section: "35787", section_end: "35796", expected_url: "/citation/39-FR-35787"}], context: {title: "50", chapter: "I", subchapter: "F", part: "82", section: "82.3"},
         with_surrounding_text: "(FMC 74-7) 34 CFR part 256, 39 FR 35787-35796, October 4, 1974"},

        # (#5) /current/title-7/subtitle-A/part-1c/section-1c.111#p-1c.111(a)(8)(i)
        {ex: "§ 1c.116(a)(1)-(4), (a)(6), and (d)",
         citations: [{title: "7", section: "1c.116", paragraph: "(a)(1)", paragraph_end: "(a)(4)"},
           {title: "7", section: "1c.116", paragraph: "(a)(6)"},
           {title: "7", section: "1c.116", paragraph: "(d)"}],
         context: {title: "7", section: "1c.111", paragraph: "(a)(8)(i)"}},

        # (#5) /current/title-21/chapter-I/subchapter-D/part-314/subpart-B/section-314.54#p-314.54(a)(1)(i)
        {ex: "§ 314.50(a), (b), (c), (d)(1), (d)(3), (e), and (g)",
         citations: [{title: "21", section: "314.50", paragraph: "(a)"},
           {title: "21", section: "314.50", paragraph: "(b)"},
           {title: "21", section: "314.50", paragraph: "(c)"},
           {title: "21", section: "314.50", paragraph: "(d)(1)"},
           {title: "21", section: "314.50", paragraph: "(d)(3)"},
           {title: "21", section: "314.50", paragraph: "(e)"},
           {title: "21", section: "314.50", paragraph: "(g)"},
           {title: "21", section: "314.50", paragraph: "(d)(1)(ii)(c)"}],
         context: {title: "21", section: "314.54", paragraph: "(a)(1)(i)"},
         with_surrounding_text: "The information required under § 314.50(a), (b), (c), (d)(1), (d)(3), (e), and (g), except that § 314.50(d)(1)(ii)(c) must contain the proposed"},

        # (#5) /current/title-40/chapter-I/subchapter-H/part-223/subpart-B/section-223.5
        {ex: "§§ 222.10 (a), (b), (d), and (e) and 222.11",
         citations: [{title: "40", section: "222.10", paragraph: "(a)"},
           {title: "40", section: "222.10", paragraph: "(b)"},
           {title: "40", section: "222.10", paragraph: "(d)"},
           {title: "40", section: "222.10", paragraph: "(e)"},
           {title: "40", section: "222.11"}],
         context: {title: "40", section: "223.5"}},

        # (#6) /current/title-7/subtitle-A/part-9/subpart-A/section-9.7#p-9.7(e)(3)(i)
        {ex: "(e)(2)(ii) and (e)(2)(iii)", citations: [{title: "7", section: "9.7", paragraph: "(e)(2)(ii)"},
          {title: "7", section: "9.7", paragraph: "(e)(2)(iii)"}], context: {title: "7", section: "9.7", paragraph: "(e)(3)(i)"},
         with_surrounding_text: "Except for payments subject to the increased payment limitation in (e)(2)(ii) and (e)(2)(iii) of this section"},

        {ex: "(e)(2)(ii) or (iii)", citations: [{title: "7", section: "9.7", paragraph: "(e)(2)(ii)"},
          {title: "7", section: "9.7", paragraph: "(e)(2)(iii)"}], context: {title: "7", section: "9.7", paragraph: "(e)(3)(i)"},
         with_surrounding_text: "limitation under (e)(2)(ii) or (iii) of this section"},

        # (#7) /current/title-24/subtitle-B/chapter-V/subchapter-C/part-570/subpart-G/section-570.456
        {ex: "paragraph (c)(1)", citation: {title: "24", section: "570.456", paragraph: "(c)(1)"}, context: {title: "24", chapter: "V", part: "570", section: "570.456"},
         with_surrounding_text: "provisions of this paragraph (c)(1) shall not apply"},

        # (#8) /current/title-17/section-240.0-1
        {ex: "paragraph (a)(3) of 17 CFR 240.0-1", citation: {title: "17", section: "240.0-1", paragraph: "(a)(3)"}, context: {title: "17", chapter: "II", part: "240", section: "240.0-1"},
         with_surrounding_text: "The provisions of paragraph (a)(3) of 17 CFR 240.0-1 relate to the terminology"},

        # (#8) /current/title-17/section-240.3a4-1#p-240.3a4-1(a)(4)(i)
        {ex: "paragraph (a)(4) (i), (ii), or (iii) of this section", citations: [{title: "17", section: "240.3a4-1", paragraph: "(a)(4) (i)"},
          {title: "17", section: "240.3a4-1", paragraph: "(a)(4) (ii)"},
          {title: "17", section: "240.3a4-1", paragraph: "(a)(4) (iii)"}], context: {title: "17", chapter: "II", part: "240", section: "240.3a4-1", paragraph: "(a)(4)(i)"},
         with_surrounding_text: "one of paragraph (a)(4) (i), (ii), or (iii) of this section"},

        # (#8) /current/title-17/section-240.3a4-1#p-240.3a4-1(a)(4)(ii)(C)
        {ex: "paragraph (a)(4)(i) or (iii) of this section", citations: [{title: "17", section: "240.3a4-1", paragraph: "(a)(4)(i)"},
          {title: "17", section: "240.3a4-1", paragraph: "(a)(4)(iii)"}], context: {title: "17", chapter: "II", part: "240", section: "240.3a4-1", paragraph: "(a)(4)(ii)(C)"}},

        # (#8) /current/title-17/section-240.3a51-1#p-240.3a51-1(e)(1)(iii)
        {ex: "paragraph (a)(1) or (a)(2) of this section", citations: [{title: "17", section: "240.3a51-1", paragraph: "(a)(1)"},
          {title: "17", section: "240.3a51-1", paragraph: "(a)(2)"}], context: {title: "17", chapter: "II", part: "240", section: "240.3a51-1", paragraph: "(e)(1)(iii)"}},

        # (#8) /current/title-17/section-240.3a51-1#p-240.3a51-1(e)(2)
        {ex: "paragraph (a), (b), (c), (d), (f), or (g) of this section", citations: [{title: "17", section: "240.3a51-1", paragraph: "(a)"},
          {title: "17", section: "240.3a51-1", paragraph: "(b)"},
          {title: "17", section: "240.3a51-1", paragraph: "(c)"},
          {title: "17", section: "240.3a51-1", paragraph: "(d)"},
          {title: "17", section: "240.3a51-1", paragraph: "(f)"},
          {title: "17", section: "240.3a51-1", paragraph: "(g)"}], context: {title: "17", chapter: "II", part: "240", section: "240.3a51-1", paragraph: "(e)(2)"}},

        # (#8) /current/title-17/section-240.6h-1#p-240.6h-1(b)(3)
        {ex: "paragraph (b)(1) or (b)(2) of this section", citations: [{title: "17", section: "240.6h-1", paragraph: "(b)(1)"},
          {title: "17", section: "240.6h-1", paragraph: "(b)(2)"}], context: {title: "17", chapter: "II", part: "240", section: "240.6h-1", paragraph: "(b)(3)"}},

        # (#9) /current/title-17/chapter-II/part-240/subpart-A/#p-240.3a44-1(b)
        {ex: "§ 240.3a43-1", citation: {title: "17", section: "240.3a43-1"}, context: {title: "17", chapter: "II", part: "240", section: "240.3a44-1", paragraph: "(b)"},
         with_surrounding_text: "under rule 3a43-1 (§ 240.3a43-1) the following"},

        # (#13) /title-11/chapter-I/subchapter-A/part-101#p-101.2(a)
        {ex: "11 CFR part 100, subparts B and C", citations: [{title: "11", part: "100", subpart: "B"},
          {title: "11", part: "100", subpart: "C"}], context: {title: "11", chapter: "I", subchapter: "A", part: "101", section: "101.2", paragraph: "(c)(3)"},
         with_surrounding_text: "defined at 11 CFR part 100, subparts B and C obtains any loan"},

        # (#15) (#16) /current/title-37/chapter-II/subchapter-A/part-201#p-201.16(c)(3)
        {ex: "paragraphs (c)(1) or (2)", citations: [{title: "37", section: "201.16", paragraph: "(c)(1)"},
          {title: "37", section: "201.16", paragraph: "(c)(2)"}], context: {title: "37", chapter: "II", subchapter: "A", part: "201", section: "201.16", paragraph: "(c)(3)"},
         with_surrounding_text: "pursuant to paragraphs (c)(1) or (2) of this section, any other"},

        # (#16) /current/title-37/chapter-II/subchapter-A/part-201#p-201.16(c)(3)
        {ex: "paragraphs (c)(1)(i) and (ii)", citations: [{title: "37", section: "201.16", paragraph: "(c)(1)(i)"},
          {title: "37", section: "201.16", paragraph: "(c)(1)(ii)"}], context: {title: "37", chapter: "II", subchapter: "A", part: "201", section: "201.16", paragraph: "(c)(3)"},
         with_surrounding_text: "specified in paragraphs (c)(1)(i) and (ii) of this section"},

        # (#16) /title-37/chapter-II/subchapter-A/part-201#p-201.16(c)(4)
        {ex: "paragraphs (c)(1) through (3)", citations: [{title: "37", section: "201.16", paragraph: "(c)(1)"},
          {title: "37", section: "201.16", paragraph: "(c)(3)"}], context: {title: "37", chapter: "II", subchapter: "A", part: "201", section: "201.16", paragraph: "(c)(4)"},
         with_surrounding_text: "the Office under paragraphs (c)(1) through (3) of this section"},

        # (#16) /title-37/chapter-II/subchapter-A/part-201#p-201.16(c)(4)
        {ex: "paragraphs (c)(1)(i)(A) through (E) of this section", citations: [{title: "40", section: "63.3094", paragraph: "(c)(1)(i)(A)"},
          {title: "40", section: "63.3094", paragraph: "(c)(1)(i)(E)"}], context: {title: "40", section: " 63.3094 ", paragraph: "(c)(1)(i)"},
         with_surrounding_text: "techniques listed in paragraphs (c)(1)(i)(A) through (E) of this section, or"},

        # /current/title-7/subtitle-A/part-9/subpart-A/section-9.4#p-9.4(d)
        {ex: "§ 9.203(a) or (b)", citations: [{title: "7", section: "9.203", paragraph: "(a)"},
          {title: "7", section: "9.203", paragraph: "(b)"}], context: {title: "7", section: "9.4", paragraph: "(d)"},
         with_surrounding_text: "subject to § 9.203(a) or (b) must file"},

        # /current/title-37/chapter-III/subchapter-B/part-350
        {ex: "parts 351 through 354 of this subchapter", citations: [{title: "37", chapter: "III", subchapter: "C", part: "351"},
          {title: "37", chapter: "III", subchapter: "C", part: "354"}], context: {title: "37", chapter: "III", subchapter: "C", part: "350"},
         with_surrounding_text: "procedures set forth in parts 351 through 354 of this subchapter shall govern"},

        {ex: "part 355 of this subchapter", citation: {title: "37", chapter: "III", subchapter: "C", part: "355"}, context: {title: "37", chapter: "III", subchapter: "C", part: "350"}},

        {ex: "§§ 240.15c3-1e(a)(1)(viii)(G), 240.15c3-1e(a)(1)(ix)(C) and (a)(4), 240.18a-1(d)(2), and 240.15c3-1g(b)(1)(i)(H), and (b)(2)(i)(C) of this chapter",
         citations: [
           {title: "17", chapter: "II", section: "240.15c3-1e", paragraph: "(a)(1)(viii)(G)"},
           {title: "17", chapter: "II", section: "240.15c3-1e", paragraph: "(a)(1)(ix)(C)"},
           {title: "17", chapter: "II", section: "240.15c3-1e", paragraph: "(a)(4)"},
           {title: "17", chapter: "II", section: "240.18a-1", paragraph: "(d)(2)"},
           {title: "17", chapter: "II", section: "240.15c3-1g", paragraph: "(b)(1)(i)(H)"},
           {title: "17", chapter: "II", section: "240.15c3-1g", paragraph: "(b)(2)(i)(C)"}
         ], context: {title: "17", chapter: "II", part: "200"},
         with_surrounding_text: "pursuant to §§ 240.15c3-1e(a)(1)(viii)(G), 240.15c3-1e(a)(1)(ix)(C) and (a)(4), 240.18a-1(d)(2), and 240.15c3-1g(b)(1)(i)(H), and (b)(2)(i)(C) of this chapter"},

        {ex: "§§ 240.14e-4(c), 240.14e-5(d), and 240.15c2-11(h) of this chapter",
         citations: [
           {title: "17", chapter: "II", section: "240.14e-4", paragraph: "(c)"},
           {title: "17", chapter: "II", section: "240.14e-5", paragraph: "(d)"},
           {title: "17", chapter: "II", section: "240.15c2-11", paragraph: "(h)"}
         ], context: {title: "17", chapter: "II", part: "200.30-3"}},

        # /current/title-7/subtitle-A/part-9/subpart-A/section-9.4#p-9.4(d)
        {ex: "appendix B of this part",
         citation: {title: "40", part: "191", appendix: "B"},
         context: {title: "40", chapter: "I", subchapter: "F", part: "191", section: "191.15", paragraph: "(b)"},
         with_surrounding_text: "calculated in accordance with appendix B of this part.",
         expected_url: "/current/title-40/part-191/appendix-Appendix%20B%20to%20Part%20191"},

        {ex: "part 121 or part 135 of this chapter", citations: [{title: "40", chapter: "I", part: "121"},
          {title: "40", chapter: "I", part: "135"}], context: {title: "40", chapter: "I", subchapter: "A", part: "1", section: "1.1"}},

        # avoid grabbing trailing date
        {ex: "40 CFR 273.13, 273.33, and 273.52",
         citations: [{title: "40", section: "273.13"}, {title: "40", section: "273.33"}, {title: "40", section: "273.52"}],
         with_surrounding_text: "40 CFR 273.13, 273.33, and 273.52, 6/7/2021"},

        # (#19)
        {ex: "subpart C, D, E, or G of this part", citations: [{title: "19", part: "206", subpart: "C"},
          {title: "19", part: "206", subpart: "D"},
          {title: "19", part: "206", subpart: "E"},
          {title: "19", part: "206", subpart: "G"}], context: {title: "19", part: "206", section: "206.5"}},

        # (#19)
        {ex: "Paragraphs (a) and (b) in § 206.3", citations: [{title: "19", section: "206.3", paragraph: "(a)"},
          {title: "19", section: "206.3", paragraph: "(b)"}], context: {title: "19", part: "206", section: "206.64"}},

        # (#19) subdivision (i) of this subparagraph /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR632c5067a0ebd91#p-1.562-1(b)(1)(ii)(a)
        # (#19) see (c) of this subdivision (ii)     /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR632c5067a0ebd91#p-1.562-1(b)(2)(ii)(b)(3)
        # (#19) subparagraph (4) of this paragraph   /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR0fae723d7dddcf0#p-1.582-1(e)(1)(ii)

        # (#19)
        {ex: "§§ 101.8 to 101.15", citation: {title: "29", section: "101.8", section_end: "101.15"}, context: {title: "29", section: "101.36"},
         with_surrounding_text: "outlined in §§ 101.8 to 101.15, inclusive."}

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
