require "spec_helper"

RSpec.describe ReferenceParser::Cfr do

  let(:lorem){ "Lorem ipsum dolor sit amet, consectetur adipiscing elit."}

  describe "per DDH" do # Document Drafting Handbook

    SCENERIOS_CFR = [
      "DDH table 2-7 (p68/2-50)", [
        {ex: "1 CFR chapter I",                      citation: {title: "1", chapter: "I"}},
        {ex: "1 CFR part 2",                         citation: {title: "1", chapter: "I", part: "2"},                                       optional: [:chapter]},
        {ex: "1 CFR 2.7",                            citation: {title: "1", chapter: "I", part: "2", section: "2.7"},                       optional: [:chapter, :part]},
        {ex: "1 CFR 2.7(a)(2)",                      citation: {title: "1", chapter: "I", part: "2", section: "2.7", paragraph: "(a)(2)"} , optional: [:chapter, :part]},
      ],
      "DDH table 2-8 (p68/2-50)", [
        {ex: "chapter II of this title",             citation: {title: "1", chapter: "II"},                                                context: {title: "1", chapter: "I"},                    context_specific: true}, 
        {ex: "part 300 of this title",               citation: {title: "1", chapter: "I", part: "300"},              optional: [:chapter], context: {title: "1", chapter: "I", part: "100"},       context_specific: true}, 
        {ex: "§ 300.19 of this title",               citation: {title: "1", chapter: "I", section: "300.19"},        optional: [:chapter], context: {title: "1", chapter: "I", section: "250.10"}, context_specific: true},
        {ex: "part 30 of this chapter",              citation: {title: "1", chapter: "I", part: "30"},               optional: [:chapter], context: {title: "1", chapter: "I", part: "20"},        context_specific: true},
        {ex: "part 30, subpart A of this chapter",   citation: {title: "1", chapter: "I", part: "30", subpart: "A"}, optional: [:chapter], context: {title: "1", chapter: "I", section: "20.10"},  context_specific: true},
        {ex: "§ 30.19 of this chapter",              citation: {title: "1", chapter: "III", section: "30.19"},       optional: [:chapter], context: {title: "1", chapter: "I", section: "20.10"},  context_specific: true},
      ],
      "DDH table 2-9 (p69/2-51)", [
        {ex: "subpart A of this part",               citation: {title: "1", part: "20", subpart: "A"},              context: {title: "1", part: "20", section: "20.5"},
                                                     expected_url: "/current/title-1/part-20/subpart-A", context_specific: true}, 
        {ex: "§ 20.15",                              citation: {title: "1", section: "20.15"},                      context: {title: "1", section: "20.5"}, context_specific: true}, 
        {ex: "§ 20.15(a)",                           citation: {title: "1", section: "20.15", paragraph: "(a)"},    context: {title: "1", section: "20.5"}, context_specific: true},
        {ex: "Appendix A of this part",              citation: {title: "1", part: "20", section: "Appendix A"},     context: {title: "1", part: "20", section: "20.5"}, context_specific: true},
      ],
      "DDH table 2-10 (p69/2-51)", [
        {ex: "paragraph (b) of this section",        text: "paragraph (b)",        citation: {title: "1", section: "1", paragraph: "(b)"},        context: {title: "1", section: "1", paragraph: "(a)"},        context_specific: true,}, 
        {ex: "paragraph (b)(1) of this section",     text: "paragraph (b)(1)",     citation: {title: "1", section: "1", paragraph: "(b)(1)"},     context: {title: "1", section: "1", paragraph: "(a)"},        context_specific: true}, 
        {ex: "paragraph (a)(2) of this section",     text: "paragraph (a)(2)",     citation: {title: "1", section: "1", paragraph: "(a)(2)"},     context: {title: "1", section: "1", paragraph: "(a)(1)"},     context_specific: true}, 
        {ex: "paragraph (a)(1)(ii) of this section", text: "paragraph (a)(1)(ii)", citation: {title: "1", section: "1", paragraph: "(a)(1)(ii)"}, context: {title: "1", section: "1", paragraph: "(a)(1)(ii)"}, context_specific: true}, 
       #{ex: "this paragraph (a)",                   text: "paragraph (a)",        citation: {title: "1", paragraph: "(a)"},                      context: {title: "1", section: "1", paragraph: "(a)"},        context_specific: true}, 
      ],
      "DDH table 2-7 (p68/2-50) (damaged)", [
        {ex: "1CFRchapterI",                         citation: {title: "1", chapter: "I"}},
        {ex: "1CFRpart2",                            citation: {title: "1", chapter: "I", part: "2"},                                      optional: [:chapter]  },
        {ex: "1CFR2.7",                              citation: {title: "1", chapter: "I", part: "2", section: "2.7"},                      optional: [:chapter, :part]  },
        {ex: "1CFR2.7(a)(2)",                        citation: {title: "1", chapter: "I", part: "2", section: "2.7", paragraph: "(a)(2)"}, optional: [:chapter, :part]}
      ],

      "buest guess / suggestions", [
        {ex: "Title 14 § 1266.102",                     options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", section: "1266.102", }},
        {ex: "Title 14 Chapter V Part 1266 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102", }},
        {ex: "Title 1 Chapter I Subchapter B",          options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B" }},
        {ex: "Title 1 Chap I Subchapter B",             options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B" }},
        {ex: "Title 1 Ch I Subch B",                    options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B" }},
        {ex: "14 Chapter V Part 1266 § 1266.102",       options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102", }},
        {ex: "1 Chapter I Subchapter B",                options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B" }},
        {ex: "14/1266",                                 options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", part: "1266", }},
      ],
      
      "extracts", [
        {ex: "40 CFR 273.13, 273.33, and 273.52",  citations: [{title: "40", section: "273.13"},
                                                               {title: "40", section: "273.33"},
                                                               {title: "40", section: "273.52"}]},
        {ex: "§ 273.9",                              citation: {title: "1",  section: "273.9"},  context: {title: "1", }, context_specific: true,
         with_surrounding_text: "chapter and § 273.9 will be amended"  },

        {ex: "§ 173.60",                           citations: [{title: "49",  section: "173.60"}],  context: {title: "49", section: "173.1"}, context_specific: true, 
         with_surrounding_text: "§ 173.60 through 1 CFR"  }, # don"t grab upcoming full reference

        {ex: "§§ 173.60 through 173.62",           citations: [{title: "49",  section: "173.60"},
                                                               {title: "49",  section: "173.62"}],  context: {title: "49", section: "173.1"}, context_specific: true, },

        {ex: "subpart C of part 261 of this chapter",citation: {title: "40", chapter: "I", part: "261", subpart: "C"}, optional: [:chapter], context: {title: "40", chapter: "I", subchapter: "I", part: "273", subpart: "G", section: "273.81"},
                                                            expected_url: "/current/title-40/part-261/subpart-C"}, # expanded as: /current/title-40/chapter-I/subchapter-I/part-261/subpart-C

        {ex: "36 CFR parts 1252-1258",               citation: {title: "36",  part: "1252", part_end: "1258"}, context: {title: "1", chapter: "I", subchapter: "A", part: "3", section: "3.3"}, 
         with_surrounding_text: "in the National Archives (36 CFR parts 1252-1258) govern", expected_url: "/current/title-36/part-1252"},

        {ex: "34 CFR part 256",           citation: {title: "34",  part: "256"}, context: {title: "50", chapter: "I", subchapter: "F", part: "82", section: "82.3"},
         with_surrounding_text: "(FMC 74-7) 34 CFR part 256, 39 FR 35787-35796, October 4, 1974"                                                              },

         

       #{ex: "part 121 or part 135 of this chapter",citations:[{title: "40", chapter: "I", part: "121"}
       #                                                              {title: "40", chapter: "I", part: "135"}], optional: [:chapter], context: {title: "14", chapter: "I", subchapter: "A", part: "1", section: "1.1"}, },

      ],

      "26 CFR 1.704-1 (paragraphs)", [ # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFR3c407b470bde109/section-1.704-1
        {ex: "paragraphs (b) through (e) of this section",     citations: [{title: "26", section: "1.704-1", paragraph: "(b)"},
                                                                                    {title: "26", section: "1.704-1", paragraph: "(e)"}],  context: {title: "26", section: "1.704-1"},
         with_surrounding_text: "and paragraphs (b) through (e) of this section. For", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)"},

        {ex: "paragraph (b)(4)(iv)(<em>a</em>) of this section", text: "paragraph (b)(4)(iv)(<em>a</em>)", citation: {title: "26", section: "1.704-1", paragraph: "(b)(4)(iv)(<em>a</em>)"}, context: {title: "26", section: "1.704-1"},
         with_surrounding_text: "as defined in paragraph (b)(4)(iv)(<em>a</em>) of this section) an allocation", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)(4)(iv)(a)"},
 
        {ex: "paragraphs (b)(2)(ii)(f), (b)(2)(ii)(h), and (b)(4)(vi) of this section", citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(ii)(f)"},
                                                                                                             {title: "26", section: "1.704-1", paragraph: "(b)(2)(ii)(h)"},
                                                                                                             {title: "26", section: "1.704-1", paragraph: "(b)(4)(vi)"}  ],  context: {title: "26", section: "1.704-1"},
         with_surrounding_text: "See paragraphs (b)(2)(ii)(f), (b)(2)(ii)(h), and (b)(4)(vi) of this section for other rules regarding such obligation", expected_url: "/current/title-26/section-1.704-1#p-1.704-1(b)(2)(ii)(f)"},

        {ex: "Paragraphs (b)(2)(iii)(a) (last sentence), (b)(2)(iii)(d), (b)(2)(iii)(e), and (b)(5) <em>Example 28</em>, <em>Example 29</em>, and <em>Example 30</em> of this section", # Example 28, Example 29, and Example 30 of this section", 
                                                            citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(a)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(d)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iii)(e)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(5)"},],  context: {title: "26", section: "1.704-1"},},

        {ex: "paragraph (b)(2)(iv)(<em>d</em>)(<em>4</em>), paragraph (b)(2)(iv)(<em>f</em>)(<em>1</em>), paragraph (b)(2)(iv)(<em>f</em>)(<em>5</em>)(<em>iv</em>), paragraph (b)(2)(iv)(<em>h</em>)(<em>2</em>), paragraph (b)(2)(iv)(<em>s</em>), paragraph (b)(4)(ix), paragraph (b)(4)(x), and <em>Examples 31</em> through <em>35</em> in paragraph (b)(5) of this section",
                                                            citations: [{title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>d</em>)(<em>4</em>)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>f</em>)(<em>1</em>)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>f</em>)(<em>5</em>)(<em>iv</em>)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>h</em>)(<em>2</em>)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(2)(iv)(<em>s</em>)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(4)(ix)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(4)(x)"},
                                                                        {title: "26", section: "1.704-1", paragraph: "(b)(5)"},
                                                                        ],  context: {title: "26", section: "1.704-1"},},

        {ex: "§§ 1.861-8 and 1.861-8T",     citations: [{title: "26", section: "1.861-8"},
                                                               {title: "26", section: "1.861-8T"}],  context: {title: "26", section: "1.704-1"},
         with_surrounding_text: "rules of §§ 1.861-8 and 1.861-8T. Under", },
          
        {ex: "1.704-1(b)(1)(ii)(b)(1)", context_specific: true,    citation: {title: "26", section: "1.704-1", paragraph: "(b)(1)(ii)(b)(1)"},  context: {title: "26", section: "1.704-1"}, },

        {ex: "26 CFR 1.704-1T(b)(4)(viii)(d)(3)",     citation: {title: "26", section: "1.704-1T", paragraph: "(b)(4)(viii)(d)(3)"},  context: {title: "26", section: "1.704-1"},
          with_surrounding_text: "2015. See 26 CFR 1.704-1T(b)(4)(viii)(d)(3) (revise", expected_url: "/current/title-26/section-1.704-1T#p-1.704-1T(b)(4)(viii)(d)(3)"},

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
        {ex: "5.73", context_specific: true,    citation: :expect_none,  context: {title: "14", section: "5.73"}, 
         with_surrounding_text: ">§ 5.73 Safety performance assessment.", },


        # don't link paragraph identifiers
        {ex: "1266.102(c)", context_specific: true, citation: :expect_none, html_appearace: :expect_none, context: {title: "14", section: "1266.102(c)"}, 
         with_surrounding_text: '<div id="p-1266.102(c)"></div>', },

        {ex: "1266.102(c)", context_specific: true, citation: :expect_none, html_appearace: :expect_none, context: {title: "14", section: "1266.102(c)"}, 
         with_surrounding_text: "<div id='p-1266.102(c)'></div>", },


        # don't link section identifiers
        {ex: '<div class="section" id="1.100">...</div>', context_specific: true, citation: :expect_none, html_appearace: :expect_none, context: {title: "1", section: "1.100"},},
        {ex: "<div class='section' id='1.100'>...</div>", context_specific: true, citation: :expect_none, html_appearace: :expect_none, context: {title: "1", section: "1.100"},},         

        {ex: "section 1506 of title 44, United States Code", citation: :expect_none, html_appearace: :expect_none, context: {title: "1", section: "1.1"}, 
         with_surrounding_text: "established under section 1506 of title 44, United States Code", },

        {ex: "Section 1258.14", citation: :expect_none, html_appearace: :expect_none, context: {title: "1", section: "3.3"}, 
         with_surrounding_text: "them. Section 1258.14 of those regulations", },


        # (future) inter-section 
        {ex: "section 4471 of the Internal Revenue Code", citation: :expect_none, html_appearace: :expect_none, context: {title: "26", section: "43.0-1"}, 
         with_surrounding_text: "transportation by water imposed by section 4471 of the Internal Revenue Code.", },

        {ex: "section 3", citation: :expect_none, html_appearace: :expect_none, context: {title: "8", section: "101", paragraph: "(d)"}, 
         with_surrounding_text: "Asiatic zone defined in section 3 of the Act of February 5, 1917", },

        {ex: "section 104(d)", citation: :expect_none, html_appearace: :expect_none, context: {title: "40", section: "223.2", paragraph: "(a)"}, 
         with_surrounding_text: "proceedings under section 104(d) of the Marine Protection, Research, and Sanctuaries Act of 1972, as amended (33 [IGNORE USC] 1414(d)), to revise, revoke or limit the terms and conditions of any permit issued pursuant to section 102 of the Act. Section 104(d) provides that", },
                           
         
        # incomplete context / invalid link generation
        {ex: "chapter II of this title", citation: :expect_none, html_appearace: :expect_none, context: {title: nil, chapter: "I"}}, 
        {ex: "chapter II of this title", citation: :expect_none, html_appearace: :expect_none, context: {chapter: "I"}}, 
        {ex: "chapter II of this title", citation: :expect_none, html_appearace: :expect_none, context: {}}, 
        {ex: "chapter II of this title", citation: :expect_none, html_appearace: :expect_none, context: {a: "b"}}, 

        {ex: "paragraph (b) of this section", citation: :expect_none, html_appearace: :expect_none, context: {title: nil, chapter: "I", part: "5", section: "5.9"}}, 
        {ex: "paragraph (b) of this section", citation: :expect_none, html_appearace: :expect_none, context: {title: "1", chapter: "I", part: "5"}},  
        {ex: "paragraph (b) of this section", citation: :expect_none, html_appearace: :expect_none, context: {title: "1", chapter: "I"}}, 
        {ex: "paragraph (b) of this section", citation: :expect_none, html_appearace: :expect_none, context: {title: "1"}}, 

      ],

      "26 CFR 1.761-1", [ # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFRe603023ccb74ecf/section-1.761-1
        {ex: "paragraph (a)(1)(ii) of § 1.731-1",     citation: {title: "26", section: "1.731-1", paragraph: "(a)(1)(ii)"},  context: {title: "26", section: "1.761-1"},
         expected_url: "/current/title-26/section-1.731-1#p-1.731-1(a)(1)(ii)"},


        {ex: "§§ 301.7701-1, 301.7701-2, and 301.7701-3 of this chapter", citations: [{title: "26", section: "301.7701-1"},
                                                                                      {title: "26", section: "301.7701-2"},
                                                                                      {title: "26", section: "301.7701-3"},],  context: {title: "26", section: "1.761-1"},},

      ],     

      "issues/recent changes", [
        {ex: "14 CFR 401, 404, 413-415, 417, 420", citations: [{title: "14", section: "401"},
                                                               {title: "14", section: "404"},
                                                               {title: "14", section: "413", section_end: "415"},
                                                               {title: "14", section: "417"},
                                                               {title: "14", section: "420"}]},
      ],

      "mentioned", [
        {ex: "33 CFR part 154, subpart P", citation: {title: "33", part: "154", subpart: "P"}, context: {title: "46", section: "39.1009"},
          with_surrounding_text: "facilities contained in 33 CFR part 154, subpart P need to be", expected_url: "/current/title-33/part-154/subpart-P"},
        
        {ex: "subtitle B of this title", citation: {title: "2", subtitle: "B"}, context: {title: "2", part: "1", section: "220"},
          with_surrounding_text: "agency regulations in subtitle B of this title and/or in policy and", expected_url: "/current/title-2/subtitle-B"},

        # {ex: "46 CFR chapter I, subchapters F and J", citation: {title: "46", chapter: "I", subchapter: "F"}, context: {title: "46", part: "39", section: "39.1009"},
        #   with_surrounding_text: "the requirements of 46 CFR chapter I, subchapters F and J apply", expected_url: "/current/title-46/chapter-I/subchapter-F"},

        {ex: "26 CFR 1.1311(a)-1",    citation: {title: "26", section: "1.1311(a)-1"}, context: {title: "17", part: "200", section: "800"},
                                             expected_url: "/current/title-26/section-1.1311(a)-1"},
        {ex: "26 CFR 1.1311(a)-1(c)", citation: {title: "26", section: "1.1311(a)-1", paragraph: "(c)"}, context: {title: "17", part: "200", section: "800"},
                                             expected_url: "/current/title-26/section-1.1311(a)-1#p-1.1311(a)-1(c)"},

        # (T) temporary rule
        {ex: "17 CFR 240.11a1-1(T)",  citation: {title: "17", section: "240.11a1-1(T)"}, context: {title: "17", part: "200", section: "800"},
                                             expected_url: "/current/title-17/section-240.11a1-1(T)"},

        {ex: "17 CFR 270.6e-3(T)",    citation: {title: "17", section: "270.6e-3(T)"}, context: {title: "17", part: "200", section: "800"},
                                             expected_url: "/current/title-17/section-270.6e-3(T)"},

        {ex: "14 CFR § 1266.102",     citation: {title: "14", section: "1266.102"},},
      ],

      "prior examples", [
        {ex: "10 CFR 100",                           url_options: {title: "10", part: "100"} },
        {ex: "10 CFR 100.1",                         url_options: {title: "10", part: "100", section: "1"}, },
        {ex: "10 C.F.R. 100.1",                      url_options: {title: "10", part: "100", section: "1"}, },
        {ex: "10 C.F.R. Part 100.1",                 url_options: {title: "10", part: "100", section: "1"}, },
        {ex: "10 C.F.R. parts 100",                  url_options: {title: "10", part: "100"}, },
        {ex: "10 C.F.R. Sec. 100",                      citation: {title: "10", section: "100"}, },
        {ex: "10 CFR 660.71 and 11 CFR 12",         url_options: [{title: "10", part: "660", section: "71"},
                                                                         {title: "11", part: "12"}], },
  
        {ex: "10 CFR § 100",                            citation: {title: "10", section: "100"}, },
        {ex: "10 C.F.R. §§ 100",                        citation: {title: "10", section: "100"}, },
        {ex: "10 C.F.R 100.214(a)",                  url_options: {title: "10", part: "100", section: "214", sublocators: "(a)"}, },
  
        {ex: "10 C.F.R 100.214(1)",                  url_options: {title: "10", part: "100", section: "214", sublocators: "(1)"}, },
  
        {ex: "10 C.F.R 100.214(a)(1)(xiii)",         url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}, },
        {ex: "10 C.F.R 100.214 (a) (1) (xiii)",      url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}, },
  
  
        {ex: "10 CFR section 54.506",                url_options: {title: "10", part: "54", section: "506", sublocators: nil },          
         with_surrounding_text: "10 CFR section 54.506 (see note)" },
    
        {ex: "49 CFR230.105(c)",                     url_options: {title: "49", part: "230", section: "105", sublocators: "(c)"}, },
        
        {ex: "12 CFR § 8360.0-7",                    url_options: {title: "12", part: "8360", section: "0-7"},          
         with_surrounding_text: "12 CFR § 8360.0-7 (and see the footnotes)" },          
  
        {ex: "12 CFR Sec 360.0-7(f)",                url_options: {title: "12", part: "360", section: "0-7", sublocators: "(f)"}, },
        {ex: "12 C.F.R. 9903.201b",                  url_options: {title: "12", part: "9903", section: "201b", sublocators: nil }, },
        {ex: "12 C.F.R. 9903a.201",                  url_options: {title: "12", part: "9903a", section: "201"}, },
        {ex: "12 CFR § 240.10b-21",                  url_options: {title: "12", part: "240", section: "10b-21"}, },
        {ex: "12 CFR § 970-1.1",                     url_options: {title: "12", part: "970-1", section: "1"}, },
        {ex: "12 CFR Part 970-1.3102-02",            url_options: {title: "12", part: "970-1", section: "3102-02"}, },
        {ex: "12 CFR Part 970-1.3102-02(i)(ii)",     url_options: {title: "12", part: "970-1", section: "3102-02", sublocators: "(i)(ii)"}, },
        {ex: "12 CFR § 970.3102-05-30-70",           url_options: {title: "12", part: "970", section: "3102-05-30-70"}, },
  
        {ex: "12 C.F.R. section 1.1031(a)-1",        url_options: {title: "12", part: "1", section: "1031(a)-1", sublocators: nil }, },
        {ex: "12 CFR § 240.15c1-1",                  url_options: {title: "12", part: "240", section: "15c1-1"}, },
        {ex: "12 CFR § 275.206(3)-3",                url_options: {title: "12", part: "275", section: "206(3)-3"}, },
        {ex: "12 CFR § 275.206(a)(3)-3",             url_options: {title: "12", part: "275", section: "206(a)(3)-3"}, },
  
        {ex: "12 CFR § 275.206(1)(a)(3)-3(1)",       url_options: {title: "12", part: "275", section: "206(1)(a)(3)-3", sublocators: "(1)"}, },
  
        {ex: "15 CFR parts 4 and 903",              url_options: [{title: "15", part: "4", },
                                                                  {title: "15", part: "903"} ], },
  
        {ex: "33 CFR Parts 160, 161, 164, and 165",  url_options:[{title: "33", part: "160"},
                                                                  {title: "33", part: "161"},
                                                                  {title: "33", part: "164"},
                                                                  {title: "33", part: "165"} ], },
  
        {ex: "18 CFR 385.214 or 385.211",           url_options: [{title: "18", part: "385", section: "214"},
                                                                  {title: "18", part: "385", section: "211"}], },
  
        {ex: "7 CFR 2.22, 2.80, and 371.3",         url_options: [{title: "7", part: "2", section: "22"},
                                                                  {title: "7", part: "2", section: "80"},
                                                                  {title: "7", part: "371", section: "3"}], },
  
      ],

      "from cfr citation parser spec", [
        {ex: "5 CFR 500.5",           options: {cfr: {best_guess: true}},                    citation: {title: "5", section: "500.5", }},
        {ex: "1 cfr 100",             options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100", }},
        {ex: "1 cfr 100",             options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "100", }},
        {ex: "1 c.f.r. 100",          options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100", }},
        {ex: "1 c.f.r. 100",          options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "100", }},
       #{ex: "29 CFR 102, Subpt. B",  options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "29", part: "102"}},
        {ex: "29 CFR 102",            options: {cfr: {best_guess: true}},                    citation: {title: "29", section: "102"}, with_surrounding_text: "29 CFR 102, Subpt. B"},
        {ex: "5 CFR 500.5",           options: {cfr: {best_guess: true}},                    citation: {title: "5", section: "500.5", }},
        {ex: "8 CFR",                 options: {cfr: {best_guess: true}},                    citation: {title: "8", }},
        {ex: "26 CFR 1.36B-0",        options: {cfr: {best_guess: true}},                    citation: {title: "26", section: "1.36B-0", }},
       #{ex: "26 CFR 1 3.14",         options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "3.14", }},
       #{ex: "26 CFR 1 Sec. 2-3",     options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "2-3", }},
        {ex: "41 CFR 102-118.35",     options: {cfr: {best_guess: true}},                    citation: {title: "41", section: "102-118.35", }},
        {ex: "41 CFR 102a.35",        options: {cfr: {best_guess: true}},                    citation: {title: "41", section: "102a.35", }},
       #{ex: "1 CFR 1.505(c)",        options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.505(c)", }},
        {ex: "1 CFR 1.25-1T",         options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.25-1T", }},
        {ex: "1 CFR 1.25A-1",         options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.25A-1", }},
        {ex: "1 CFR 1.25-1T",         options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.25-1T", }},
        {ex: "1 CFR 1.36B-3T",        options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.36B-3T", }},
        {ex: "1 CFR 1.103(n)-7T",     options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.103(n)-7T", }},
        {ex: "1 CFR 1.381(c)(18)-1",  options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.381(c)(18)-1", }},
        {ex: "1 CFR",                 options: {cfr: {best_guess: true}},                    citation: {title: "1", }, with_surrounding_text: "1 CFR Food" },
      ],
    ]

    include RSpecHtmlMatchers

    SCENERIOS_CFR.each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].truncate(24)}" do

            # embed example in text
            i = rand(lorem.length)
            text = lorem[0..i] << " " << (example[:with_surrounding_text] || example[:ex]) << " " << lorem[i..-1] << "."
            expected_citation = [example[:citation], example[:citations]].flatten.compact.map do |target| 
              target.respond_to?(:except) ? target.except(*example[:optional]) : target
            end
            expected_prior_urls = [example[:url_options]].flatten.compact

            result_html, references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: example[:context]}}))
            
            if expected_citation.present?
              if [:expect_none] == expected_citation
                expect(references.map{ |r| r[:hierarchy]}.compact).to be_empty
              else
                # verify extracted references (if present)
                expect(references.map{ |r| r[:hierarchy]}.compact).to eq(expected_citation)
              end
            end
            
            # verify expected_prior_urls (if present)
            expected_prior_urls.each do |expected_prior_url|
              href = prior_url_helper(:current, expected_prior_url)
              expect(result_html).to have_tag("a", with: { href: href })
            end


            # confirm linking didn't damage source text
            references_only_result_html = references.map{|r| r[:result]}.join
            references_only_result_html_text = Nokogiri::HTML.parse(references_only_result_html).text
            result_html_text = Nokogiri::HTML.parse(result_html).text


            expect(references_only_result_html_text).to include(Nokogiri::HTML.parse(example[:text] || example[:ex]).text) unless expected_prior_urls.present? || (expected_citation == [:expect_none])
            expect(result_html_text).to include(Nokogiri::HTML.parse(example[:ex]).text) unless example[:html_appearace] == :expect_none
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
                                   with: { href: example[:expected_url] }.tap{ |h| h.delete(:href) unless h[:href].present?})
              end
            end

            if example[:context_specific]
              # confirm same results w/ composite hierarchy
              composite_hierarchy = "#{example.dig(:context, :title)}:#{example.dig(:context, :subtitle)}:#{example.dig(:context, :chapter)}:#{example.dig(:context, :subchapter)}:#{example.dig(:context, :part)}:#{example.dig(:context, :subpart)}:#{example.dig(:context, :section)}"
              composite_result_html, composite_references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: { composite_hierarchy: composite_hierarchy}}}))
              expect(composite_result_html).to eq(result_html)
              expect(composite_references).to eq(references)
            end
          end
        end
      end
    end

    LOREM_PARAGRAPH = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

    def all_non_context_specific_examples
      SCENERIOS_CFR.each_slice(2).map do |description, examples| 
        result = examples.select do |example| 
          !example[:context_specific] && example[:expected_prior_urls]&.empty?
        end
        result
      end.flatten
    end

    def all_non_context_specific_examples_references
      all_non_context_specific_examples.map{ |e| e[:reference]} 
    end

    def consolidated_example
      @consolidated_example ||= begin
        result = ""      
        all_non_context_specific_examples_references.each do |reference|
          result << LOREM_PARAGRAPH[0..1 + rand(64)]
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
        expected_citations = all_non_context_specific_examples.map{ |e| [e[:citations], e[:citation]]}.flatten.compact

        expect(references.map{ |r| r[:citation] || r[:citations]}.count).to eq(expected_citations.count)

        references_html = references.map{|r| r[:result]}.join()

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
      return '' unless hierarchy[:part]
      return "/part-#{hierarchy[:part]}" unless hierarchy[:section]
      "/section-#{hierarchy[:part]}.#{hierarchy[:section]}"
    end
  
    def sublocators_string(hierarchy)
      return '' unless hierarchy[:sublocators]  
      "#p-#{hierarchy[:part]}.#{hierarchy[:section]}#{hierarchy[:sublocators]}"
    end  
    
    def prior_url_helper(date, hierarchy)
      path = "/current" if :current == date
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

  describe "links USC" do
    it "misc issue usage" do
      expect(

        ReferenceParser.new(only: :cfr, options: {cfr: {slash_shorthand_allowed: true}}).hyperlink(
          "49/147, 150", 
          default: {target: nil, class: nil, relative: true}
        )
  
      ).to eql "<a href='/current/title-49/part-147'>49/147</a>, <a href='/current/title-49/part-150'>150</a>"
    end
  end
end
