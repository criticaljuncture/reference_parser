require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "extracts" do
    [
      "(20-29)", [

        # (#20)
        {ex: "3 CFR", citations: [{title: "3"}], html_appearance: :expect_none, context: {title: "29", section: "100.603"},
         with_surrounding_text: "(3 CFR, 1980 Comp., pp. 409-412)"},
        {ex: "3 CFR", citations: [{title: "3"}], html_appearance: :expect_none, context: {title: "1", part: "2"},
         with_surrounding_text: "3 CFR, 1954-1958 Comp."},

        # (#20)
        {ex: ">9.400 Scope of subpart.<", citation: :expect_none, html_appearance: :expect_none, context: {title: "48", section: "9.400"}},

        # (#20)
        {ex: ">§ 20.510 Fraud or false statements", citation: :expect_none, html_appearance: :expect_none, context: {title: "43", section: "20.510"}},

        {ex: "Section 744.9 of the EAR imposes", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
        {ex: "See § 734.2(a) of the EAR for items", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
        {ex: "See §§ 742.6 and 746.3 of the EAR", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},
        {ex: "See § 740.11(b)(1) of the EAR for the definition of 'agency of the U.S. Government' and § 740.11(c)(1) for the definition of 'agency of a cooperating government.'", citation: :expect_none, html_appearance: :expect_none, context: {title: "15", section: "774"}},

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

        # #24 /current/title-21/chapter-I/subchapter-D/part-314/subpart-A/section-314.1
        {ex: "subchapter F of chapter I of title 21 of the Code of Federal Regulations", citation: {title: "21", chapter: "I", subchapter: "F"}},

        # IBR
        {ex: "7 CFR Part 210, Appendix A", citation: {title: "7", part: "210", appendix: "A"},
         expected_url: "/current/title-7/part-210/appendix-Appendix%20A%20to%20Part%20210"},

        {ex: "paragraph (a)(2)", context: {title: "14", chapter: "I", part: "61", subchapter: "D", appendix: "Special Federal Aviation Regulation No. 73"},
         with_surrounding_text: "Except as provided in paragraph (a)(2) of this section, no person may manipulate",
         expected_url: "/current/title-14/appendix-Special%20Federal%20Aviation%20Regulation%20No.%2073#p-Special-Federal-Aviation-Regulation-No.-73(a)(2)"},

        {ex: "paragraph (a)(2)", context: {composite_hierarchy: "14::I:D:61::Special Federal Aviation Regulation No. 73"},
         with_surrounding_text: "Except as provided in paragraph (a)(2) of this section, no person may manipulate",
         expected_url: "/current/title-14/appendix-Special%20Federal%20Aviation%20Regulation%20No.%2073#p-Special-Federal-Aviation-Regulation-No.-73(a)(2)"},

        # #27 /on/2020-09-11/title-21/chapter-I/subchapter-C/part-201/subpart-C/section-201.66#p-201.66(c)(5)(ii)(C)
        {ex: "§§ 341.74(c)(5)(iii)", context: {composite_hierarchy: "21::I:C:201:C:201.66"},
         with_surrounding_text: "(e.g., §§ 341.74(c)(5)(iii), 344.52(c), 358.150(c), and 358.550(c) of this chapter).",
         citations: [
           {title: "21", chapter: "I", section: "341.74", paragraph: "(c)(5)(iii)"},
           {title: "21", chapter: "I", section: "344.52", paragraph: "(c)"},
           {title: "21", chapter: "I", section: "358.150", paragraph: "(c)"},
           {title: "21", chapter: "I", section: "358.550", paragraph: "(c)"}
         ],
         expected_url: "/on/2020-09-11/title-21/section-341.74#p-341.74(c)(5)(iii)"}
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
