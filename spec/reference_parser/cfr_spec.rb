require "spec_helper"

SCENERIOS_CFR = [
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
  ],

  "buest guess / suggestions", [
    {ex: "Title 14 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", section: "1266.102"}},
    {ex: "Title 14 Chapter V Part 1266 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102"}},
    {ex: "Title 1 Chapter I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
    {ex: "Title 1 Chap I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
    {ex: "Title 1 Ch I Subch B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
    {ex: "14 Chapter V Part 1266 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102"}},
    {ex: "1 Chapter I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
    {ex: "14/1266", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", part: "1266"}},
    {ex: "41 CFR subpart 101-19.6", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "41", subpart: "101-19.6"}},
    {ex: "21 558.128", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "21", section: "558.128"}},
    {ex: "48 CFR Supbart 816.70", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "48", subpart: "816.70"}},
    {ex: "48 CFR Ch. 7, Appendix D", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "48", chapter: "7", appendix: "D"}},
    {ex: "50 CFR Table 1b to Part 660, Subpart C", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "50", part: "660", subpart: "C", table: "1b"},
     expected_url: "/current/title-50/part-660/subpart-C/appendix-Table%201b%20to%20Part%20660,%20Subpart%20C"}

    # Citations
    # {ex: "Appendix J to Part 50, Title 10", citation: {title: "10", part: "50", appendix: "J"},
    #  expected_url: "/current/title-10/chapter-I/part-50/appendix-Appendix%20J%20to%20Part%2050"}
  ],

  "extracts", [
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
     with_surrounding_text: "outlined in §§ 101.8 to 101.15, inclusive."},

    # (#20)
    {ex: "31 CFR chapter IX § 901.1", text: "31 CFR chapter IX § 901.1", citation: {title: "31", chapter: "IX", section: "901.1"}, context: {title: "29", section: "100.609"},
     expected_url: "/current/title-31/section-901.1"},

    # (#20)
    {ex: "1 CFR part 51", citations: [{title: "5", section: "552", paragraph: "(a)"}, {title: "1", part: "51"}], context: {title: "39", section: "20.1"},
     with_surrounding_text: "5 U.S.C. 552(a) and 1 CFR part 51."},

    # (#20)
    {ex: "5 CFR part 2634, subpart J", citation: {title: "5", part: "2634", subpart: "J"}, context: {title: "43", section: "20.602"},
     with_surrounding_text: "See 5 CFR part 2634, subpart J."},

    # (#20) trailing orem
    {ex: "5 CFR part 2634, subpart J", citation: {title: "5", part: "2634", subpart: "J"}, context: {title: "43", section: "20.602"},
     with_surrounding_text: "Lo See 5 CFR part 2634, subpart J. orem ipsum"},

    {ex: "29 CFR 102.119(a), (b), (c), (d), (e), and (f)", citations: [{title: "29", section: "102.119", paragraph: "(a)"},
      {title: "29", section: "102.119", paragraph: "(b)"},
      {title: "29", section: "102.119", paragraph: "(c)"},
      {title: "29", section: "102.119", paragraph: "(d)"},
      {title: "29", section: "102.119", paragraph: "(e)"},
      {title: "29", section: "102.119", paragraph: "(f)"}], context: {title: "29", section: "102.119"},
     with_surrounding_text: "and from 29 CFR 102.119(a), (b), (c), (d), (e), and (f), insofar as the system"},

    {ex: "part 17 of this chapter", citation: {title: "1", chapter: "I", part: "17"}, context: {title: "1", chapter: "I", subchapter: "A", part: "1", section: "1.1"}},

    # (badger 404) /current/title-49/subtitle-A/part-38/subpart-H/section-38.175
    {ex: "§§ 38.111(d), 38.113 (a) through (c) and (e), 38.115 (a) and (b), 38.117 (a) and (b), 38.121 through 38.123, 38.125(d), and 38.127", citations: [
      {title: "49", section: "38.111", paragraph: "(d)"},
      {title: "49", section: "38.113", paragraph: "(a)"},
      {title: "49", section: "38.113", paragraph: "(c)"},
      {title: "49", section: "38.113", paragraph: "(e)"},
      {title: "49", section: "38.115", paragraph: "(a)"},
      {title: "49", section: "38.115", paragraph: "(b)"},
      {title: "49", section: "38.117", paragraph: "(a)"},
      {title: "49", section: "38.117", paragraph: "(b)"},
      {title: "49", section: "38.121"},
      {title: "49", section: "38.123"},
      {title: "49", section: "38.125", paragraph: "(d)"},
      {title: "49", section: "38.127"}
    ], context: {title: "49", section: "38.175"}},

    # /current/title-49/section-382.217
    {ex: "49 CFR part 40, subpart O", citation: {title: "49", part: "40", subpart: "O"}, context: {title: "49", section: "382.217"},
     with_surrounding_text: "requirements in 49 CFR part 40, subpart O, after the"},

    # /current/title-30/section-585.612
    {ex: "15 CFR part 930, subpart D", citation: {title: "15", part: "930", subpart: "D"}, context: {title: "30", section: "585.612"},
     with_surrounding_text: "pursuant to 15 CFR part 930, subpart D, to the applicable"},

    # /current/title-30/section-585.612
    {ex: "15 CFR part 930, subpart E", citation: {title: "15", part: "930", subpart: "E"}, context: {title: "30", section: "585.612"},
     with_surrounding_text: "under 15 CFR part 930, subpart E, after BOEM"},

    # /current/title-30/section-585.647
    {ex: "15 CFR 930, subpart E", citation: {title: "15", part: "930", subpart: "E"}, context: {title: "30", section: "585.647"},
     with_surrounding_text: "pursuant to 15 CFR 930, subpart E to BOEM"},

    # /current/title-9/section-317.380
    {ex: "Paragraph (e)(1)", citation: {title: "9", section: "317.380", paragraph: "(e)(1)"}, context: {title: "9", section: "317.380"},
     with_surrounding_text: "Paragraph (e)(1) of this section shall not apply to any"},

    # /current/title-10/section-490.307
    {ex: "10 CFR part 1003, subpart C", citation: {title: "10", part: "1003", subpart: "C"}, context: {title: "10", section: "490.307"},
     with_surrounding_text: "pursuant to 10 CFR part 1003, subpart C, with the",
     expected_url: "/current/title-10/part-1003/subpart-C"},

    # /current/title-10/appendix-Appendix%20B%20to%20Part%20851
    {ex: "10 CFR part 1003, Subpart G", citation: {title: "10", part: "1003", subpart: "G"}, context: {title: "10", appendix: "Appendix%20B%20to%20Part%20851"},
     with_surrounding_text: "accordance with 10 CFR part 1003, Subpart G, within 30 calendar"},

    # /current/title-10/section-429.53
    {ex: "10 CFR part 431, subpart R, appendix C", citation: {title: "10", part: "431", subpart: "R", appendix: "C"}, context: {title: "10", appendix: "429.53"},
     with_surrounding_text: "test procedure in 10 CFR part 431, subpart R, appendix C. Follow",
     expected_url: "/current/title-10/part-431/subpart-R/appendix-Appendix%20C%20to%20Part%20431"},

    # /current/title-12/section-238.153
    {ex: "12 CFR part 217, subparts D and E", citations: [{title: "12", part: "217", subpart: "D"},
      {title: "12", part: "217", subpart: "E"}], context: {title: "12", appendix: "238.153"},
     with_surrounding_text: "use under 12 CFR part 217, subparts D and E to value"},

    # /current/title-42/section-51c.112
    {ex: "45 CFR 75.307, 75.371 through 75.385, and 75.316-75.325", citations: [
      {title: "45", section: "75.307"},
      {title: "45", section: "75.371"},
      {title: "45", section: "75.385"},
      {title: "45", section: "75.316", section_end: "75.325"}
    ], context: {title: "42", section: "51c.112"},
     with_surrounding_text: "Any other amounts due pursuant to 45 CFR 75.307, 75.371 through 75.385, and 75.316-75.325."},

    # /current/title-32/section-117.15
    {ex: "32 CFR 2001.45(a)(1) and 2001.43 (c)", citations: [
      {title: "32", section: "2001.45", paragraph: "(a)(1)"},
      {title: "32", section: "2001.43", paragraph: "(c)"}
    ], context: {title: "42", section: "117.15"},
     with_surrounding_text: "will follow the guidance in 32 CFR 2001.45(a)(1) and 2001.43 (c) to address"},

    # /current/title-12/section-25.01
    {ex: "§§ 25.07 - 25.13, 25.21, 25.25, and 25.26", citations: [
      {title: "12", section: "25.07", section_end: "25.13"},
      {title: "12", section: "25.21"},
      {title: "12", section: "25.25"},
      {title: "12", section: "25.26"}
    ], context: {title: "12", section: "25.01"},
     with_surrounding_text: "banks must comply with §§ 25.07 - 25.13, 25.21, 25.25, and 25.26 by January 1, 2023."},

    # /current/title-19/section-351.301
    {ex: "§ 351.102(b)(21)(i)-(iv)", citations: [
      {title: "19", section: "351.102", paragraph: "(b)(21)(i)", paragraph_end: "(b)(21)(iv)"}
    ], context: {title: "19", section: "351.301"},
     with_surrounding_text: "does not satisfy the definitions described in § 351.102(b)(21)(i)-(iv)."},

    # /current/title-20/section-725.209
    {ex: "§§ 404.367-404.369 of this title", citations: [
      {title: "20", section: "404.367", section_end: "404.369"}
    ], context: {title: "20", section: "725.209"},
     with_surrounding_text: "(see §§ 404.367-404.369 of this title), or an"},

    # /current/title-24/section-206.107
    {ex: "§ 206.123(a)(3)-(5)", citation: {title: "24", section: "206.123", paragraph: "(a)(3)", paragraph_end: "(a)(5)"}, context: {title: "24", section: "206.107"},
     with_surrounding_text: "any of the circumstances described in § 206.123(a)(3)-(5); and"},

    # #21 /current/title-46/section-160.132-7
    {ex: "§ 160.132-5 of this subpart", citation: {title: "46", part: "160", section: "160.132-5"}, context: {title: "46", chapter: "I", subchapter: "Q", part: "160", subpart: "160.132", section: "160.132-7"},
     with_surrounding_text: "VI/6.1 (incorporated by reference, see § 160.132-5 of this subpart) applicable", expected_url: "/current/title-46/part-160/section-160.132-5"},

    # #21 /current/title-46/section-69.11
    {ex: "subpart B of this part", citation: {title: "46", chapter: "I", part: "69", subpart: "B"}, context: {title: "46", chapter: "I", subchapter: "G", part: "69", subpart: "A", section: "69.11"},
     with_surrounding_text: "(subpart B of this part)", expected_url: "/current/title-46/part-69/subpart-B"},

    # {ex: "granted merit status under 35 CFR chapter I, subchapter E;", citation: {title: "35", chapter: "I", subchapter: "E"}, context: {title: "5", section: "831.201"}}

    # # table of local references /current/title-26/section-1.704-1
    # {ex: "1.704-1(b)(2)(iv)(<em>k</em>)(<em>3</em>)", citation: {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>k</em>)(<em>3</em>)"}, context: {title: "26", section: "1.704-1"},
    #  with_surrounding_text: '<td class="align-left">1.704-1(b)(2)(iv)(<em>k</em>)(<em>3</em>) </td>'}

    # /current/title-10/section-55.46
    # ensure that paragraphs (c)(2)(ii), as applicable, and (d)(3) of this section are met

    # #24 /current/title-31/subtitle-A/part-29/subpart-A/section-29.102
    {ex: "Part 581 of Title 5, Code of Federal Regulations", citation: {title: "5", part: "581"}},

    # # #24 /current/title-31/subtitle-A/part-29/subpart-A/section-29.102
    # {ex: "Parts 835 and 845 and subparts M, N, and R of part 831 of title 5, Code of Federal Regulations",
    #   citations: [
    #     {title: "5", part: "835"},
    #     {title: "5", part: "845"},
    #     {title: "5", part: "831", subpart: "M"},
    #     {title: "5", part: "831", subpart: "N"},
    #     {title: "5", part: "831", subpart: "R"},
    #   ]
    # },

    # #24 /current/title-33/chapter-I/subchapter-O/part-159/subpart-C/section-159.97
    {ex: "subchapter F of Title 46, Code of Federal Regulations", citation: {title: "46", subchapter: "F"},
     expected_url: "/current/title-46/subchapter-F"},

    # #24 /current/title-48/chapter-2/subchapter-H/part-252/subpart-252.2/section-252.204-7018
    {ex: "subchapter M of chapter I of title 22, Code of Federal Regulations", citation: {title: "22", chapter: "I", subchapter: "M"},
     expected_url: "/current/title-22/chapter-I/subchapter-M"},

    # #24 /current/title-34/subtitle-B/chapter-III/part-303/subpart-B/subject-group-ECFRcd7caaaa2680a00/section-303.104
    {ex: "Appendix A of subpart 101-19.6 of title 41, Code of Federal Regulations", citation: {title: "41", appendix: "A", subpart: "101-19.6"}},

    # #24
    {ex: "Appendix A of part 36 of title 28, Code of Federal Regulations", citation: {title: "28", appendix: "A", part: "36"},
     expected_url: "/current/title-28/part-36/appendix-Appendix%20A%20to%20Part%2036"},

    # #24 https://ecfr.federalregister.gov/current/title-21/chapter-I/subchapter-D/part-314/subpart-A/section-314.1
    {ex: "subchapter F of chapter I of title 21 of the Code of Federal Regulations", citation: {title: "21", chapter: "I", subchapter: "F"}},

    # IBR
    {ex: "7 CFR Part 210, Appendix A", citation: {title: "7", part: "210", appendix: "A"},
     expected_url: "/current/title-7/part-210/appendix-Appendix%20A%20to%20Part%20210"},

    {ex: "paragraph (a)(2)", context: {title: "14", chapter: "I", part: "61", subchapter: "D", appendix: "Special Federal Aviation Regulation No. 73"},
     with_surrounding_text: "Except as provided in paragraph (a)(2) of this section, no person may manipulate",
     expected_url: "/current/title-14/appendix-Special%20Federal%20Aviation%20Regulation%20No.%2073#p-Special-Federal-Aviation-Regulation-No.-73(a)(2)"},

    {ex: "paragraph (a)(2)", context: {composite_hierarchy: "14::I:D:61::Special Federal Aviation Regulation No. 73"},
     with_surrounding_text: "Except as provided in paragraph (a)(2) of this section, no person may manipulate",
     expected_url: "/current/title-14/appendix-Special%20Federal%20Aviation%20Regulation%20No.%2073#p-Special-Federal-Aviation-Regulation-No.-73(a)(2)"}
  ],

  "26 CFR 1.704-1 (paragraphs)", [ # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR3c407b470bde109/section-1.704-1
    {ex: "paragraphs (b) through (e) of this section", citations: [{title: "26", section: "1.704-1", paragraph: "(b)"},
      {title: "26", section: "1.704-1", paragraph: "(e)"}], context: {title: "26", section: "1.704-1"},
     with_surrounding_text: "and paragraphs (b) through (e) of this section. For", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)"},

    {ex: "paragraph (b)(4)(iv)(<em>a</em>) of this section", text: "paragraph (b)(4)(iv)(<em>a</em>)", citation: {title: "26", section: "1.704-1", paragraph: "(b)(4)(iv)(<em>a</em>)"}, context: {title: "26", section: "1.704-1"},
     with_surrounding_text: "as defined in paragraph (b)(4)(iv)(<em>a</em>) of this section) an allocation", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)(4)(iv)(a)"},

    {ex: "paragraphs (b)(2)(ii)(f), (b)(2)(ii)(h), and (b)(4)(vi) of this section", citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(ii)(f)"},
      {title: "26", section: "1.704-1", paragraph: "(b)(2)(ii)(h)"},
      {title: "26", section: "1.704-1", paragraph: "(b)(4)(vi)"}], context: {title: "26", section: "1.704-1"},
     with_surrounding_text: "See paragraphs (b)(2)(ii)(f), (b)(2)(ii)(h), and (b)(4)(vi) of this section for other rules regarding such obligation", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)(2)(ii)(f)"},

    {ex: "Paragraphs (b)(2)(iii)(a) (last sentence), (b)(2)(iii)(d), (b)(2)(iii)(e), and (b)(5) <em>Example 28</em>, <em>Example 29</em>, and <em>Example 30</em> of this section", # Example 28, Example 29, and Example 30 of this section",
     citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(a)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(d)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(e)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(5)"}], context: {title: "26", section: "1.704-1"}},

    {ex: "paragraph (b)(2)(iv)(<em>d</em>)(<em>4</em>), paragraph (b)(2)(iv)(<em>f</em>)(<em>1</em>), paragraph (b)(2)(iv)(<em>f</em>)(<em>5</em>)(<em>iv</em>), paragraph (b)(2)(iv)(<em>h</em>)(<em>2</em>), paragraph (b)(2)(iv)(<em>s</em>), paragraph (b)(4)(ix), paragraph (b)(4)(x), and <em>Examples 31</em> through <em>35</em> in paragraph (b)(5) of this section",
     citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>d</em>)(<em>4</em>)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>f</em>)(<em>1</em>)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>f</em>)(<em>5</em>)(<em>iv</em>)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>h</em>)(<em>2</em>)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>s</em>)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(4)(ix)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(4)(x)"},
       {title: "26", section: "1.704-1", paragraph: "(b)(5)"}], context: {title: "26", section: "1.704-1"}},

    {ex: "§§ 1.861-8 and 1.861-8T", citations: [{title: "26", section: "1.861-8"},
      {title: "26", section: "1.861-8T"}], context: {title: "26", section: "1.704-1"},
     with_surrounding_text: "rules of §§ 1.861-8 and 1.861-8T. Under"},

    {ex: "1.704-1(b)(1)(ii)(b)(1)", context_specific: true, citation: {title: "26", section: "1.704-1", paragraph: "(b)(1)(ii)(b)(1)"}, context: {title: "26", section: "1.704-1"}},

    {ex: "26 CFR 1.704-1T(b)(4)(viii)(d)(3)", citation: {title: "26", section: "1.704-1T", paragraph: "(b)(4)(viii)(d)(3)"}, context: {title: "26", section: "1.704-1"},
     with_surrounding_text: "2015. See 26 CFR 1.704-1T(b)(4)(viii)(d)(3) (revise", expected_url: "/current/title-26/section-1.704-1T#p-1.704-1T(b)(4)(viii)(d)(3)"},

    {ex: "§ 301.6230(e)-1T contained in 26 CFR part 1", citation: {title: "26", part: "1", section: "301.6230(e)-1T"}, context: {title: "99", section: "1"}}

    # provisions of paragraphs (b)(4)(viii)(a)(1), (b)(4)(viii)(c)(1), (b)(4)(viii)(c)(2)(ii) and (iii), (b)(4)(viii)(c)(3) and (4), and (b)(4)(viii)(d)(1) (as in effect on July 24, 2019) and in paragraphs (b)(6)(i), (ii), and (iii) of this section

    # § 1.704-1(b)(4)(viii)(c)(3)(ii) and (b)(4)(viii)(d)(3)
    # the provisions of § 1.704-1(b)(4)(viii)(c)(3)(ii) and (b)(4)(viii)(d)(3) (see

    # see § 1.704-1(b)(1)(ii)(b), (b)(4)(viii)(a)(1), (b)(4)(viii)(c)(1), (b)(4)(viii)(c)(2)(ii) and (iii), (b)(4)(viii)(c)(3) and (4), (b)(4)(viii)(d)(1), and (b)(5), Example 25

  ],

  "standalone section handling", [
    # {ex: "section 761(c)",     citation: {title: "26", section: "761", paragraph: "(c)"},  context: {title: "26", section: "1.704-1"},
    #  with_surrounding_text: "a agreement see section 761(c).", expected_url: "/current/title-26/section-761#p-761(c)"},

  ],

  "false positives / html", [

    # don't link the section header w/ the context specific section pattern
    {ex: "5.73", context_specific: true, citation: :expect_none, context: {title: "14", section: "5.73"},
     with_surrounding_text: ">§ 5.73 Safety performance assessment."},

    # (#14) /title-34/subtitle-B/chapter-IV/part-462
    {ex: "§§ 462.43-462.44   [Reserved]", context_specific: true, citation: :expect_none, context: {title: "34", part: "462   "},
     with_surrounding_text: "<h8>§§ 462.43-462.44   [Reserved]</h8>"},

    # (#14) /current/title-17/chapter-II/part-240/subpart-A/#240.3a4-2---240.3a4-6
    {ex: "§§ 240.3a4-2-240.3a4-6   [Reserved]", context_specific: true, citation: :expect_none, context: {title: "17", section: "240.3a4-2"},
     with_surrounding_text: "<h8>§§ 240.3a4-2-240.3a4-6   [Reserved]</h8>"},

    # don't link paragraph identifiers
    {ex: "1266.102(c)", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "14", section: "1266.102(c)"},
     with_surrounding_text: '<div id="p-1266.102(c)"></div>'},

    {ex: "1266.102(c)", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "14", section: "1266.102(c)"},
     with_surrounding_text: "<div id='p-1266.102(c)'></div>"},

    # don't link section identifiers
    {ex: '<div class="section" id="1.100">...</div>', context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "1", section: "1.100"}},
    {ex: "<div class='section' id='1.100'>...</div>", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "1", section: "1.100"}},

    {ex: '<div class="appendix" id="Appendix-to-19-CFR-Part-0">', context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "19", section: "Appendix to 19 CFR Part 0"}},
    {ex: ">Appendix to 19 CFR Part 0 - Treasury Department Order No. 100-16 <", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "19", section: "Appendix to 19 CFR Part 0"}},
    {ex: "Appendix B to 5 CFR Chapter XIV - Memorandum", citation: :expect_none, html_appearance: :expect_none, context: {title: "5", section: "Appendix B to 5 CFR Chapter XIV"}},
    {ex: ">Appendix B to 5 CFR Chapter XIV - Memorandum", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "5", section: "Appendix B to 5 CFR Chapter XIV"}},
    {ex: "Appendix to Subpart B of 2 CFR Part 176 - U.S. States", context_specific: true, citation: :expect_none, html_appearance: :expect_none, context: {title: "2", section: "Appendix to Subpart B of 2 CFR Part 176"}},

    {ex: "section 1506 of title 44, United States Code", options: {only: [:cfr]}, citation: :expect_none, html_appearance: :expect_none, context: {title: "1", section: "1.1"},
     with_surrounding_text: "established under section 1506 of title 44, United States Code"},

    {ex: "Section 1258.14", citation: :expect_none, html_appearance: :expect_none, context: {title: "1", section: "3.3"},
     with_surrounding_text: "them. Section 1258.14 of those regulations"},

    # (#10) avoid USC §
    {ex: "5 U.S.C. § 5584", options: {only: [:cfr]}, citation: :expect_none, html_appearance: :expect_none, context: {title: "31", part: "5"},
     with_surrounding_text: "a. 5 U.S.C. § 5584 authorizes the waiver"},

    {ex: "5 U.S.C. § 5584", options: {only: [:cfr, :usc]}, citation: {title: "5", section: "5584"}, context: {title: "31", part: "5"},
     with_surrounding_text: "a. 5 U.S.C. § 5584 authorizes the waiver", expected_url: "https://www.govinfo.gov/link/uscode/5/5584"},

    {ex: "5 U.S.C. § 5584", options: {only: [:usc]}, citation: {title: "5", section: "5584"}, context: {title: "31", part: "5"},
     with_surrounding_text: "a. 5 U.S.C. § 5584 authorizes the waiver", expected_url: "https://www.govinfo.gov/link/uscode/5/5584"},

    {ex: "5 U.S.C. § 5514(a)(2)(D)", options: {only: [:cfr]}, citation: :expect_none, html_appearance: :expect_none, context: {title: "31", part: "5"},
     with_surrounding_text: "under 5 U.S.C. § 5514(a)(2)(D) for a hearing", expected_url: "https://www.govinfo.gov/link/uscode/5/5514"},

    {ex: "5 U.S.C. § 5514(a)(2)(D)", options: {only: [:cfr, :usc]}, citation: {title: "5", section: "5514", paragraph: "(a)(2)(D)"}, context: {title: "31", part: "5"},
     with_surrounding_text: "under 5 U.S.C. § 5514(a)(2)(D) for a hearing", expected_url: "https://www.govinfo.gov/link/uscode/5/5514"},

    {ex: "5 U.S.C. § 5514(a)(2)(D)", options: {only: [:usc]}, citation: {title: "5", section: "5514", paragraph: "(a)(2)(D)"}, context: {title: "31", part: "5"},
     with_surrounding_text: "under 5 U.S.C. § 5514(a)(2)(D) for a hearing", expected_url: "https://www.govinfo.gov/link/uscode/5/5514"},

    # {ex: "", citation: :expect_none, html_appearance: :expect_none, context: {title: "31", part: "5"},
    #  with_surrounding_text: "The General Accounting Office Act of 1996 (Pub. L. 104-316), Title I, § 103(d), enacted October 19, 1996", },

    # (future) inter-section
    {ex: "section 4471 of the Internal Revenue Code", citation: :expect_none, html_appearance: :expect_none, context: {title: "26", section: "43.0-1"},
     with_surrounding_text: "transportation by water imposed by section 4471 of the Internal Revenue Code."},

    {ex: "section 3", citation: :expect_none, html_appearance: :expect_none, context: {title: "8", section: "101", paragraph: "(d)"},
     with_surrounding_text: "Asiatic zone defined in section 3 of the Act of February 5, 1917"},

    {ex: "section 104(d)", citation: :expect_none, html_appearance: :expect_none, context: {title: "40", section: "223.2", paragraph: "(a)"},
     with_surrounding_text: "proceedings under section 104(d) of the Marine Protection, Research, and Sanctuaries Act of 1972, as amended (33 [IGNORE USC] 1414(d)), to revise, revoke or limit the terms and conditions of any permit issued pursuant to section 102 of the Act. Section 104(d) provides that"},

    # incomplete context / invalid link generation
    {ex: "chapter II of this title", citation: :expect_none, html_appearance: :expect_none, context: {title: nil, chapter: "I"}},
    {ex: "chapter II of this title", citation: :expect_none, html_appearance: :expect_none, context: {chapter: "I"}},
    {ex: "chapter II of this title", citation: :expect_none, html_appearance: :expect_none, context: {}},
    {ex: "chapter II of this title", citation: :expect_none, html_appearance: :expect_none, context: {a: "b"}},

    {ex: "paragraph (b) of this section", citation: :expect_none, html_appearance: :expect_none, context: {title: nil, chapter: "I", part: "5", section: "5.9"}},
    {ex: "paragraph (b) of this section", citation: :expect_none, html_appearance: :expect_none, context: {title: "1", chapter: "I", part: "5"}},
    {ex: "paragraph (b) of this section", citation: :expect_none, html_appearance: :expect_none, context: {title: "1", chapter: "I"}},
    {ex: "paragraph (b) of this section", citation: :expect_none, html_appearance: :expect_none, context: {title: "1"}},

    # footnote
    {ex: '<sup>[<a class="footnote-reference" href="#406.2-footnote-1" id="406.2-footref-1" data-turbolinks="false">1</a>] </sup>', citation: :expect_none, html_appearance: :expect_none, context: {title: "29", section: "406.2"}},
    {ex: "<sup>[<a class='footnote-reference' href='#406.2-footnote-1' id='406.2-footref-1' data-turbolinks='false'>1</a>] </sup>", citation: :expect_none, html_appearance: :expect_none, context: {title: "29", section: "406.2"}},
    {ex: '<sup>[<a class="footnote-reference" href="#406.2-footref-1" data-turbolinks="false">1</a>]</sup>', citation: :expect_none, html_appearance: :expect_none, context: {title: "29", section: "406.2"}},
    {ex: "<sup>[<a class='footnote-reference' href='#406.2-footref-1' data-turbolinks='false'>1</a>]</sup>", citation: :expect_none, html_appearance: :expect_none, context: {title: "29", section: "406.2"}},

    # (#20)
    {ex: "(3 CFR, 1980 Comp., pp. 409-412)", citation: :expect_none, html_appearance: :expect_none, context: {title: "29", section: "100.603"}},

    # (#20)
    {ex: ">9.400 Scope of subpart.<", citation: :expect_none, html_appearance: :expect_none, context: {title: "48", section: "9.400"}},

    # (#20)
    {ex: ">§ 20.510 Fraud or false statements", citation: :expect_none, html_appearance: :expect_none, context: {title: "43", section: "20.510"}},

    {ex: "Section 744.9 of the EAR imposes", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
    {ex: "See § 734.2(a) of the EAR for items", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
    {ex: "See §§ 742.6 and 746.3 of the EAR", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
    {ex: "See § 740.11(b)(1) of the EAR for the definition of 'agency of the U.S. Government' and § 740.11(c)(1) for the definition of 'agency of a cooperating government.'", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},

    # typo resulting in title zero
    {ex: "Central Mass Intrastate Area (See 4r0 CFR 81.142)", citation: :expect_none, html_appearance: :expect_none, context: {title: "40", section: "52.1127"}},

    # corrupted text
    {ex: "The regulati2 CFR 200.3332 CFR 200.3332 CFR 200.33356 FR 37004, Aug. 2, 1991", citation: :expect_none, html_appearance: :expect_none, context: {title: "23", section: "635.601"}},

    # /current/title-32/section-2001.43
    {ex: "required under section 5.4(d)(2) of the Order", citation: :expect_none, html_appearance: :expect_none, context: {title: "32", section: "2001.43"}},

    # /current/title-15/subtitle-B/chapter-VII/subchapter-C/part-744/appendix-Supplement%20No.%207%20to%20Part%20744
    {ex: "entities listed in supplement no. 7 to part 744 applies to the", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", appendix: "Supplement%20No.%207%20to%20Part%20744"}},

    # /current/title-26/section-301.6230(e)-1
    {ex: "see § 301.6230(e)-1T contained in 26 CFR part 1, revised April 1, 2001", citation: :expect_none, html_appearance: :expect_none, context: {title: "26", section: "301.6230(e)-1"}},

    # /current/title-16/chapter-II/subchapter-B/part-1450/section-1450.3
    {ex: "Section 3.2.4 of ANSI/APSP/ICC-16 2017", citation: :expect_none, html_appearance: :expect_none, context: {title: "16", section: "1450.3"}}
  ],

  "26 CFR 1.761-1", [ # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFRe603023ccb74ecf/section-1.761-1
    {ex: "paragraph (a)(1)(ii) of § 1.731-1", citation: {title: "26", section: "1.731-1", paragraph: "(a)(1)(ii)"}, context: {title: "26", section: "1.761-1"},
     expected_url: "/current/title-26/section-1.731-1#p-1.731-1(a)(1)(ii)"},

    {ex: "§§ 301.7701-1, 301.7701-2, and 301.7701-3 of this chapter", citations: [{title: "26", section: "301.7701-1"},
      {title: "26", section: "301.7701-2"},
      {title: "26", section: "301.7701-3"}], context: {title: "26", section: "1.761-1"}}

  ],

  "issues/recent changes", [
    {ex: "14 CFR 401, 404, 413-415, 417, 420", citations: [{title: "14", section: "401"},
      {title: "14", section: "404"},
      {title: "14", section: "413", section_end: "415"},
      {title: "14", section: "417"},
      {title: "14", section: "420"}]},
    {ex: "41 CFR 50-203, 60-30", citations: [{title: "41", section: "50-203"},
      {title: "41", section: "60-30"}]}
  ],

  "mentioned", [
    {ex: "33 CFR part 154, subpart P", citation: {title: "33", part: "154", subpart: "P"}, context: {title: "46", section: "39.1009"},
     with_surrounding_text: "facilities contained in 33 CFR part 154, subpart P need to be", expected_url: "/current/title-33/part-154/subpart-P"},

    {ex: "subtitle B of this title", citation: {title: "2", subtitle: "B"}, context: {title: "2", part: "1", section: "220"},
     with_surrounding_text: "agency regulations in subtitle B of this title and/or in policy and", expected_url: "/current/title-2/subtitle-B"},

    # {ex: "46 CFR chapter I, subchapters F and J", citations: [{title: "46", chapter: "I"},
    #   {title: "46", chapter: "I", subchapter: "F"},
    #   {title: "46", chapter: "I", subchapter: "J"}], context: {title: "46", part: "39", section: "39.1009"},
    #  with_surrounding_text: "the requirements of 46 CFR chapter I, subchapters F and J apply", expected_url: "/current/title-46/chapter-I/subchapter-F"},

    {ex: "26 CFR 1.1311(a)-1", citation: {title: "26", section: "1.1311(a)-1"}, context: {title: "17", part: "200", section: "800"},
     expected_url: "/current/title-26/section-1.1311(a)-1"},
    {ex: "26 CFR 1.1311(a)-1(c)", citation: {title: "26", section: "1.1311(a)-1", paragraph: "(c)"}, context: {title: "17", part: "200", section: "800"},
     expected_url: "/current/title-26/section-1.1311(a)-1#p-1.1311(a)-1(c)"},

    # (T) temporary rule
    {ex: "17 CFR 240.11a1-1(T)", citation: {title: "17", section: "240.11a1-1(T)"}, context: {title: "17", part: "200", section: "800"},
     expected_url: "/current/title-17/section-240.11a1-1(T)"},

    {ex: "17 CFR 270.6e-3(T)", citation: {title: "17", section: "270.6e-3(T)"}, context: {title: "17", part: "200", section: "800"},
     expected_url: "/current/title-17/section-270.6e-3(T)"},

    {ex: "14 CFR § 1266.102", citation: {title: "14", section: "1266.102"}}
  ],

  "prior examples", [
    {ex: "10 CFR 100", url_options: {title: "10", part: "100"}},
    {ex: "10 CFR 100.1", url_options: {title: "10", part: "100", section: "1"}},
    {ex: "10 C.F.R. 100.1", url_options: {title: "10", part: "100", section: "1"}},
    {ex: "10 C.F.R. Part 100.1", url_options: {title: "10", part: "100", section: "1"}},
    {ex: "10 C.F.R. parts 100", url_options: {title: "10", part: "100"}},
    {ex: "10 C.F.R. Sec. 100", citation: {title: "10", section: "100"}},
    {ex: "10 CFR 660.71 and 11 CFR 12", url_options: [{title: "10", part: "660", section: "71"},
      {title: "11", part: "12"}]},

    {ex: "10 CFR § 100", citation: {title: "10", section: "100"}},
    {ex: "10 C.F.R. §§ 100", citation: {title: "10", section: "100"}},
    {ex: "10 C.F.R 100.214(a)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)"}},

    {ex: "10 C.F.R 100.214(1)", url_options: {title: "10", part: "100", section: "214", sublocators: "(1)"}},

    {ex: "10 C.F.R 100.214(a)(1)(xiii)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}},
    {ex: "10 C.F.R 100.214 (a) (1) (xiii)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}},

    {ex: "10 CFR section 54.506", url_options: {title: "10", part: "54", section: "506", sublocators: nil},
     with_surrounding_text: "10 CFR section 54.506 (see note)"},

    {ex: "49 CFR230.105(c)", url_options: {title: "49", part: "230", section: "105", sublocators: "(c)"}},

    {ex: "12 CFR § 8360.0-7", url_options: {title: "12", part: "8360", section: "0-7"},
     with_surrounding_text: "12 CFR § 8360.0-7 (and see the footnotes)"},

    {ex: "12 CFR Sec 360.0-7(f)", url_options: {title: "12", part: "360", section: "0-7", sublocators: "(f)"}},
    {ex: "12 C.F.R. 9903.201b", url_options: {title: "12", part: "9903", section: "201b", sublocators: nil}},
    {ex: "12 C.F.R. 9903a.201", url_options: {title: "12", part: "9903a", section: "201"}},
    {ex: "12 CFR § 240.10b-21", url_options: {title: "12", part: "240", section: "10b-21"}},
    {ex: "12 CFR § 970-1.1", url_options: {title: "12", part: "970-1", section: "1"}},
    {ex: "12 CFR Part 970-1.3102-02", url_options: {title: "12", part: "970-1", section: "3102-02"}},
    {ex: "12 CFR Part 970-1.3102-02(i)(ii)", url_options: {title: "12", part: "970-1", section: "3102-02", sublocators: "(i)(ii)"}},
    {ex: "12 CFR § 970.3102-05-30-70", url_options: {title: "12", part: "970", section: "3102-05-30-70"}},

    {ex: "12 C.F.R. section 1.1031(a)-1", url_options: {title: "12", part: "1", section: "1031(a)-1", sublocators: nil}},
    {ex: "12 CFR § 240.15c1-1", url_options: {title: "12", part: "240", section: "15c1-1"}},
    {ex: "12 CFR § 275.206(3)-3", url_options: {title: "12", part: "275", section: "206(3)-3"}},
    {ex: "12 CFR § 275.206(a)(3)-3", url_options: {title: "12", part: "275", section: "206(a)(3)-3"}},

    {ex: "12 CFR § 275.206(1)(a)(3)-3(1)", url_options: {title: "12", part: "275", section: "206(1)(a)(3)-3", sublocators: "(1)"}},

    {ex: "15 CFR parts 4 and 903", url_options: [{title: "15", part: "4"},
      {title: "15", part: "903"}]},

    {ex: "33 CFR Parts 160, 161, 164, and 165", url_options: [{title: "33", part: "160"},
      {title: "33", part: "161"},
      {title: "33", part: "164"},
      {title: "33", part: "165"}]},

    {ex: "18 CFR 385.214 or 385.211", url_options: [{title: "18", part: "385", section: "214"},
      {title: "18", part: "385", section: "211"}]},

    {ex: "7 CFR 2.22, 2.80, and 371.3", url_options: [{title: "7", part: "2", section: "22"},
      {title: "7", part: "2", section: "80"},
      {title: "7", part: "371", section: "3"}]}

  ],

  "from cfr citation parser spec", [
    # #22
    {ex: "14 CFR Chapter I", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "I"}},
    {ex: "14 CFR Chapter II Subchapter A", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "II", subchapter: "A"}},
    {ex: "14 CFR Part 25", options: {cfr: {best_guess: true}}, citation: {title: "14", part: "25"}},
    {ex: "Title 14 of the CFR", options: {cfr: {best_guess: true}}, citation: {title: "14"}},
    {ex: "2 CFR subtitle A", options: {cfr: {best_guess: true}}, citation: {title: "2", subtitle: "A"}},
    {ex: "14 CFR chapter IV", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "IV"}},
    {ex: "14 CFR chapter IV subchapter Z", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "IV", subchapter: "Z"}},
    {ex: "14 CFR part Y subpart Z", options: {cfr: {best_guess: true}}, citation: {title: "14", part: "Y", subpart: "Z"}},

    {ex: "5 CFR 500.5", options: {cfr: {best_guess: true}}, citation: {title: "5", section: "500.5"}},
    {ex: "1 cfr 100", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100"}},
    {ex: "1 cfr 100", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "100"}},
    {ex: "1 c.f.r. 100", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100"}},
    {ex: "1 c.f.r. 100", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "100"}},
    # {ex: "29 CFR 102, Subpt. B",  options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "29", part: "102"}},
    {ex: "29 CFR 102", options: {cfr: {best_guess: true}}, citation: {title: "29", section: "102"}, with_surrounding_text: "29 CFR 102, Subpt. B"},
    {ex: "5 CFR 500.5", options: {cfr: {best_guess: true}}, citation: {title: "5", section: "500.5"}},
    {ex: "8 CFR", options: {cfr: {best_guess: true}}, citation: {title: "8"}},
    {ex: "26 CFR 1.36B-0", options: {cfr: {best_guess: true}}, citation: {title: "26", section: "1.36B-0"}},
    # {ex: "26 CFR 1 3.14",         options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "3.14", }},
    # {ex: "26 CFR 1 Sec. 2-3",     options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "2-3", }},
    {ex: "41 CFR 102-118.35", options: {cfr: {best_guess: true}}, citation: {title: "41", section: "102-118.35"}},
    {ex: "41 CFR 102a.35", options: {cfr: {best_guess: true}}, citation: {title: "41", section: "102a.35"}},
    # {ex: "1 CFR 1.505(c)",        options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.505(c)", }},
    {ex: "1 CFR 1.25-1T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25-1T"}},
    {ex: "1 CFR 1.25A-1", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25A-1"}},
    {ex: "1 CFR 1.25-1T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25-1T"}},
    {ex: "1 CFR 1.36B-3T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.36B-3T"}},
    {ex: "1 CFR 1.103(n)-7T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.103(n)-7T"}},
    {ex: "1 CFR 1.381(c)(18)-1", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.381(c)(18)-1"}},
    {ex: "1 CFR", options: {cfr: {best_guess: true}}, citation: {title: "1"}, with_surrounding_text: "1 CFR Food"}
  ]
]

LOREM_PARAGRAPH = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

RSpec.describe ReferenceParser::Cfr do
  let(:lorem) { "Lorem ipsum dolor sit amet, consectetur adipiscing elit." }

  describe "per DDH" do # Document Drafting Handbook
    SCENERIOS_CFR.each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].truncate(24)}" do
            # embed example in text
            text = lorem[0..16] << " " << (example[:with_surrounding_text] || example[:ex]) << " " << lorem[18..] << "."
            expected_citation = [example[:citation], example[:citations]].flatten.compact.map do |target|
              target.respond_to?(:except) ? target.except(*example[:optional]) : target
            end
            expected_prior_urls = [example[:url_options]].flatten.compact

            result_html, references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: example[:context]}}))

            if expected_citation.present?
              if expected_citation == [:expect_none]
                expect(references.map { |r| r[:hierarchy] }.compact).to be_empty
              else
                # verify extracted references (if present)
                expect(references.map { |r| r[:hierarchy].to_h }.compact).to eq(expected_citation.map { |c| c.except(:expected_url) })

                expected_citation.map { |expected_citation| expected_citation[:expected_url] }.compact.each do |expected_url|
                  expect(result_html).to have_tag("a", with: {href: expected_url})
                end

              end
            end

            # verify expected_prior_urls (if present)
            expected_prior_urls.each do |expected_prior_url|
              href = prior_url_helper(:current, expected_prior_url)
              expect(result_html).to have_tag("a", with: {href: href})
            end

            # confirm linking didn't damage source text
            references_only_result_html = references.map { |r| r[:result] }.join
            references_only_result_html_text = Nokogiri::HTML.parse(references_only_result_html).text
            result_html_text = Nokogiri::HTML.parse(result_html).text

            expect(references_only_result_html_text).to include(Nokogiri::HTML.parse(example[:text] || example[:ex]).text) unless expected_prior_urls.present? || (expected_citation == [:expect_none])
            expect(result_html_text).to include(Nokogiri::HTML.parse(example[:ex]).text) unless example[:html_appearance] == :expect_none
            expect(result_html_text).to include(Nokogiri::HTML.parse(example[:with_surrounding_text]).text) if example[:with_surrounding_text].present?

            if expected_citation == [:expect_none]
              expect(
                references_only_result_html
              ).to_not have_tag("a")
            end

            # confirm specific url
            if references.count < 2 && (expected_citation != [:expect_none])
              if example[:text]&.include?("<") # have_tag vs <em>?
                expect(references_only_result_html).to include(example[:text] || example[:ex])
              else
                expect(
                  references_only_result_html
                ).to have_tag("a", text: example[:text] || example[:ex],
                                   with: {href: example[:expected_url]}.tap { |h| h.delete(:href) unless h[:href].present? })
              end
            end

            if example[:context_specific]
              # confirm same results w/ composite hierarchy
              composite_hierarchy = "#{example.dig(:context, :title)}:#{example.dig(:context, :subtitle)}:#{example.dig(:context, :chapter)}:#{example.dig(:context, :subchapter)}:#{example.dig(:context, :part)}:#{example.dig(:context, :subpart)}:#{example.dig(:context, :section)}"
              composite_result_html, composite_references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: {composite_hierarchy: composite_hierarchy}}}))
              expect(composite_result_html).to eq(result_html)
              expect(composite_references).to eq(references)
            end
          end
        end
      end
    end

    def all_non_context_specific_examples
      SCENERIOS_CFR.each_slice(2).map do |description, examples|
        result = examples.select do |example|
          !example[:context_specific] && example[:expected_prior_urls]&.empty?
        end
        result
      end.flatten
    end

    def all_non_context_specific_examples_references
      all_non_context_specific_examples.map { |e| e[:reference] }
    end

    def consolidated_example
      @consolidated_example ||= begin
        result = ""
        all_non_context_specific_examples_references.each do |reference|
          result << LOREM_PARAGRAPH[0..rand(1..64)]
          result << " "
          result << reference if reference
          result << ". \n" if rand(5)
        end
        result << "."
      end
    end

    describe "consolidated example" do
      it "finds everything once" do
        result_html, references = extract_references(consolidated_example, options: {cfr: {context: {title: "1", section: "1"}}})
        expected_citations = all_non_context_specific_examples.map { |e| [e[:citations], e[:citation]] }.flatten.compact

        expect(references.map { |r| r[:citation] || r[:citations] }.count).to eq(expected_citations.count)

        references_html = references.map { |r| r[:result] }.join

        # confirm linking didn't damage source text
        references_html_text = Nokogiri::HTML.parse(references_html).text
        result_html_text = Nokogiri::HTML.parse(result_html).text

        all_non_context_specific_examples_references.each do |reference|
          expect(result_html_text).to include(Nokogiri::HTML.parse(reference).text)
          expect(references_html_text).to include(Nokogiri::HTML.parse(reference).text)
        end
      end
    end

    def part_or_section_string(hierarchy)
      return "" unless hierarchy[:part]
      return "/part-#{hierarchy[:part]}" unless hierarchy[:section]
      "/section-#{hierarchy[:part]}.#{hierarchy[:section]}"
    end

    def sublocators_string(hierarchy)
      return "" unless hierarchy[:sublocators]
      "#p-#{hierarchy[:part]}.#{hierarchy[:section]}#{hierarchy[:sublocators]}"
    end

    def prior_url_helper(date, hierarchy)
      path = "/current" if date == :current
      path ||= "/on/#{date.is_a?(String) ? date : date.to_formatted_s(:iso)}"
      path += "/title-#{hierarchy[:title]}"
      path += part_or_section_string(hierarchy)
      path += sublocators_string(hierarchy)
      path
    end

    def extract_references(text, options: {})
      citations = []
      result_html = ReferenceParser.new(options: options).each(text, default: {relative: true}) do |citation|
        citations << citation
      end
      [result_html, citations]
    end
  end

  describe "links CFR" do
    it "issue shorthand usage" do
      expect(
        ReferenceParser.new(only: :cfr, options: {cfr: {slash_shorthand_allowed: true}}).hyperlink(
          "49/147, 150",
          default: {target: nil, class: nil, relative: true}
        )
      ).to eql "<a href='/current/title-49/part-147'>49/147</a>, <a href='/current/title-49/part-150'>150</a>"
    end
  end
end
