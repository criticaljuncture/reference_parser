require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "false positives & html" do
    [
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
        {ex: "Section 3.2.4 of ANSI/APSP/ICC-16 2017", citation: :expect_none, html_appearance: :expect_none, context: {title: "16", section: "1450.3"}},

        # definition title /current/title-7/subtitle-B/chapter-II/subchapter-A/part-215/section-215.2
        {ex: '<p class="indent-1" data-title="215.2 “Applicable credits shall have the meaning established in 2 CFR part 200 and USDA implementing regulations 2 CFR part 400 and part 415”" data-definition="true">', options: {html_awareness: :careful}, citation: :expect_none, html_appearance: :expect_none},

        {ex: '<tag ex="a" attribute="Lorem 1 CFR 1.1 ipsum"></tag><tag><tag></tag><tag attribute="Lorem 1 CFR 1.1 ipsum"></tag><tag></tag></tag><tag></tag>', options: {html_awareness: :careful}, citation: :expect_none, html_appearance: :expect_none},
        {ex: '<tag ex="b" ></tag><tag><tag></tag><tag attribute="Lorem 1 CFR 1.1 ipsum"></tag><tag></tag></tag><tag></tag>', options: {html_awareness: :careful}, citation: :expect_none, html_appearance: :expect_none},
        {ex: '<tag ex="c" ></tag><tag><tag></tag><tag></tag><tag></tag></tag><tag attribute="Lorem 1 CFR 1.1 ipsum"></tag>', options: {html_awareness: :careful}, citation: :expect_none, html_appearance: :expect_none},
        {ex: '<tag ex="d"  attribute="Lorem 1 CFR 1.1 ipsum"></tag><tag><tag>2 CFR 2</tag><tag attribute="Lorem 1 CFR 1.1 ipsum"></tag><tag></tag></tag><tag>3 CFR 3</tag>', options: {html_awareness: :careful},
         citations: [{title: "2", section: "2"}, {title: "3", section: "3"}], html_appearance: :expect_none},
        {ex: '<tag ex="e" ></tag><tag><tag></tag><tag attribute="Lorem 1 CFR 1.1 ipsum">2 CFR 2</tag><tag></tag></tag><tag>3 CFR 3</tag>', options: {html_awareness: :careful},
         citations: [{title: "2", section: "2"}, {title: "3", section: "3"}], html_appearance: :expect_none},
        {ex: '<tag ex="f" ></tag><tag><tag></tag><tag></tag><tag>2 CFR 2</tag></tag><tag attribute="Lorem 1 CFR 1.1 ipsum">3 CFR 3</tag>', options: {html_awareness: :careful},
         citations: [{title: "2", section: "2"}, {title: "3", section: "3"}], html_appearance: :expect_none},

        # /current/title-49/subtitle-B/chapter-I/subchapter-C/part-175/subpart-A/section-175.10#p-175.10(a)(19)
        {ex: "in the UN Manual of Tests and Criteria, Part III, Subsection 38.3. Recharging of the devices", citation: :expect_none, html_appearance: :expect_none, context: {title: "49", section: "175.10"}},

        # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR1d0453abf9d86e0/section-1.6851-2
        # expect only the dot format § prefixed loose section (other should fail qualify_match w/ :formatting)
        {ex: "§ 1.6012-1", citation: {title: "26", section: "1.6012-1"}, context: {composite_hierarchy: "26::I:A:1::1.6851-2"},
         with_surrounding_text: "the return required under section 6012 and § 1.6012-1 for the preceding taxable year"},

        # appendix cleanup
        {ex: "Section 3.4", citation: :expect_none, context: {composite_hierarchy: "10::II:D:430:B:Appendix C1 to Subpart B of Part 430"},
         with_surrounding_text: "Section 3.4 as referenced in sections 3 and 3.2 of this appendix"},

        {ex: "Section 1", citation: :expect_none, context: {composite_hierarchy: "10::II:D:431:R:Appendix A to Subpart R of Part 431"},
         with_surrounding_text: "Section 1 Scope, is inapplicable"},

        {ex: "Section 7.3", citation: :expect_none, context: {composite_hierarchy: "10::II:D:431:R:Appendix A to Subpart R of Part 431"},
         with_surrounding_text: "Section 7.3 Test Conditions, is inapplicable"},

        {ex: "§ 200.306 of this Part", citation: {part: "200", section: "200.306", title: "2"}, context: {composite_hierarchy: "2:A:II::200::Appendix I to Part 200"},
         with_surrounding_text: "as described in § 200.306 of this Part"},

        {ex: "§ 200.211", citation: {section: "200.211", title: "2"}, context: {composite_hierarchy: "2:A:II::200::Appendix I to Part 200"},
         with_surrounding_text: "See also § 200.211"},

        {ex: "7 CFR part 400, subpart R", citation: {part: "400", subpart: "R", title: "7"}, context: {composite_hierarchy: "7:B:IV::457::457.8"},
         with_surrounding_text: "in accordance with section 515(h) of the Act and 7 CFR part 400, subpart R, and any applicable civil or"}
      ]
    ].each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end
  end
end
