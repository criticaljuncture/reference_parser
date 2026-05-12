require "spec_helper"

CFR_SCENARIOS = [
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

  "26 CFR 1.761-1", [ # /current/title-26/chapter-I/subchapter-A/part-1/subject-group-ECFRe603023ccb74ecf/section-1.761-1
    {ex: "paragraph (a)(1)(ii) of § 1.731-1", citation: {title: "26", section: "1.731-1", paragraph: "(a)(1)(ii)"}, context: {title: "26", section: "1.761-1"},
     expected_url: "/current/title-26/section-1.731-1#p-1.731-1(a)(1)(ii)"},

    {ex: "§§ 301.7701-1, 301.7701-2, and 301.7701-3 of this chapter", citations: [{title: "26", section: "301.7701-1"},
      {title: "26", section: "301.7701-2"},
      {title: "26", section: "301.7701-3"}], context: {title: "26", section: "1.761-1"}}

  ],

  "Authority", [
    {ex: "44 U.S.C. 1506; sec. 6, E.O. 7531, 19 FR 2709; 3 CFR, 1954-1958 Comp., p. 189; 1 U.S.C. 112; 1 U.S.C. 113.",
     citations: [{section: "1506", title: "44"},
       {title: "19", section: "2709"},
       {title: "3"},
       {title: "1", section: "112"},
       {title: "1", section: "113"}],
     expected_html: '<a href="https://www.govinfo.gov/link/uscode/44/1506" class="usc external" target="_blank" rel="noopener noreferrer">44 U.S.C. 1506</a>; sec. 6, E.O. 7531, <a href="/citation/19-FR-2709" class="fr-reference" data-reference="19 FR 2709">19 FR 2709</a>; <a href="/current/title-3" class="cfr external">3 CFR</a>, 1954-1958 Comp., p. 189; <a href="https://www.govinfo.gov/link/uscode/1/112" class="usc external" target="_blank" rel="noopener noreferrer">1 U.S.C. 112</a>; <a href="https://www.govinfo.gov/link/uscode/1/113" class="usc external" target="_blank" rel="noopener noreferrer">1 U.S.C. 113</a>'},
    {ex: "Clean Water Act, 33 U.S.C. 1361(a), 1369(b); Clean Air Act, 42 U.S.C. 7601(a)(1), 7607(b); Resource, Conservation and Recovery Act, 42 U.S.C. 6912(a), 6976; Toxic Substances Control Act, 15 U.S.C. 2618; Federal Insecticide, Fungicide, and Rodenticide Act, 7 U.S.C. 136n(b), 136w(a); Safe Drinking Water Act, 42 U.S.C. 300j–7(a)(2), 300j–9(a); Atomic Energy Act, 42 U.S.C. 2201, 2239; Federal Food, Drug, and Cosmetic Act, 21 U.S.C. 371(a), 346a, 28 U.S.C. 2112(a), 2343, 2344.",
     citations: [{title: "33", section: "1361", paragraph: "(a)", expected_text: "33 U.S.C. 1361(a)"},
       {title: "33", section: "1369", paragraph: "(b)", expected_text: "1369(b)"},
       {title: "42", section: "7601", paragraph: "(a)(1)", expected_text: "42 U.S.C. 7601(a)(1)"},
       {title: "42", section: "7607", paragraph: "(b)", expected_text: "7607(b)"},
       {title: "42", section: "6912", paragraph: "(a)", expected_text: "42 U.S.C. 6912(a)"},
       {title: "42", section: "6976", expected_text: "6976"},
       {title: "15", section: "2618", expected_text: "15 U.S.C. 2618"},
       {title: "7", section: "136n", paragraph: "(b)", expected_text: "7 U.S.C. 136n(b)"},
       {title: "7", section: "136w", paragraph: "(a)", expected_text: "136w(a)"},
       {title: "42", section: "300j-7", paragraph: "(a)(2)", expected_text: "42 U.S.C. 300j–7(a)(2)"},
       {title: "42", section: "300j-9", paragraph: "(a)", expected_text: "300j–9(a)"},
       {title: "42", section: "2201", expected_text: "42 U.S.C. 2201"},
       {title: "42", section: "2239", expected_text: "2239"},
       {title: "21", section: "371", paragraph: "(a)", expected_text: "21 U.S.C. 371(a)"},
       {title: "21", section: "346a", expected_text: "346a"},
       {title: "28", section: "2112", paragraph: "(a)", expected_text: "28 U.S.C. 2112(a)"},
       {title: "28", section: "2343", expected_text: "2343"},
       {title: "28", section: "2344", expected_text: "2344"}]},
    {ex: "7 U.S.C. 136 to 136y; 15 U.S.C. 2601 to 2692; 33 U.S.C. 1251 to 1387; 33 U.S.C. 1401 to 1445; 33 U.S.C. 2701 to 2761; 42 U.S.C. 300f to 300j-26; 42 U.S.C. 4852d; 42 U.S.C. 6901-6992k; 42 U.S.C. 7401 to 7671q; 42 U.S.C. 9601 to 9675; 42 U.S.C. 11001 to 11050; 15 U.S.C. 7001; 44 U.S.C. 3504 to 3506",
     citations: [{title: "7", section: "136", section_end: "136y", expected_text: "7 U.S.C. 136 to 136y"},
       {title: "15", section: "2601", section_end: "2692", expected_text: "15 U.S.C. 2601 to 2692"},
       {title: "33", section: "1251", section_end: "1387", expected_text: "33 U.S.C. 1251 to 1387"},
       {title: "33", section: "1401", section_end: "1445", expected_text: "33 U.S.C. 1401 to 1445"},
       {title: "33", section: "2701", section_end: "2761", expected_text: "33 U.S.C. 2701 to 2761"},
       {title: "42", section: "300f", section_end: "300j-26", expected_text: "42 U.S.C. 300f to 300j-26"},
       {title: "42", section: "4852d", expected_text: "42 U.S.C. 4852d"},
       {title: "42", section: "6901", section_end: "6992k", expected_text: "42 U.S.C. 6901-6992k"},
       {title: "42", section: "7401", section_end: "7671q", expected_text: "42 U.S.C. 7401 to 7671q"},
       {title: "42", section: "9601", section_end: "9675", expected_text: "42 U.S.C. 9601 to 9675"},
       {title: "42", section: "11001", section_end: "11050", expected_text: "42 U.S.C. 11001 to 11050"},
       {title: "15", section: "7001", expected_text: "15 U.S.C. 7001"},
       {title: "44", section: "3504", section_end: "3506", expected_text: "44 U.S.C. 3504 to 3506"}]},
    {ex: "7 U.S.C. 136 to 136y; 15 U.S.C. 2601 to 2692; 33 U.S.C. 1251 to 1387; 33 U.S.C. 1401 to 1445; 33 U.S.C. 2701 to 2761; 42 U.S.C. 300f to 300j-26; 42 U.S.C. 4852d; 42 U.S.C. 6901-6992k; 42 U.S.C. 7401 to 7671q; 42 U.S.C. 9601 to 9675; 42 U.S.C. 11001 to 11050; 15 U.S.C. 7001; 44 U.S.C. 3504 to 3506",
     citations: [{title: "7", section: "136", section_end: "136y", expected_text: "7 U.S.C. 136 to 136y"},
       {title: "15", section: "2601", section_end: "2692", expected_text: "15 U.S.C. 2601 to 2692"},
       {title: "33", section: "1251", section_end: "1387", expected_text: "33 U.S.C. 1251 to 1387"},
       {title: "33", section: "1401", section_end: "1445", expected_text: "33 U.S.C. 1401 to 1445"},
       {title: "33", section: "2701", section_end: "2761", expected_text: "33 U.S.C. 2701 to 2761"},
       {title: "42", section: "300f", section_end: "300j-26", expected_text: "42 U.S.C. 300f to 300j-26"},
       {title: "42", section: "4852d", expected_text: "42 U.S.C. 4852d"},
       {title: "42", section: "6901", section_end: "6992k", expected_text: "42 U.S.C. 6901-6992k"},
       {title: "42", section: "7401", section_end: "7671q", expected_text: "42 U.S.C. 7401 to 7671q"},
       {title: "42", section: "9601", section_end: "9675", expected_text: "42 U.S.C. 9601 to 9675"},
       {title: "42", section: "11001", section_end: "11050", expected_text: "42 U.S.C. 11001 to 11050"},
       {title: "15", section: "7001", expected_text: "15 U.S.C. 7001"},
       {title: "44", section: "3504", section_end: "3506", expected_text: "44 U.S.C. 3504 to 3506"}]},
    {ex: "7 U.S.C. 135 <em>et seq.</em>, 136–136y; 15 U.S.C. 2001, 2003, 2005, 2006, 2601–2671; 21 U.S.C. 331j, 346a, 31 U.S.C. 9701; 33 U.S.C. 1251 <em>et seq.</em>, 1311, 1313d, 1314, 1318, 1321, 1326, 1330, 1342, 1344, 1345 (d) and (e), 1361; E.O. 11735, 38 FR 21243, 3 CFR, 1971–1975 Comp. p. 973; 42 U.S.C. 241, 242b, 243, 246, 300f, 300g, 300g–1, 300g–2, 300g–3, 300g–4, 300g–5, 300g–6, 300j–1, 300j–2, 300j–3, 300j–4, 300j–9, 1857 <em>et seq.</em>, 6901–6992k, 7401–7671q, 7542, 9601–9657, 11023, 11048.",
     citations: [
       {title: "7", section: "135", expected_text: "7 U.S.C. 135 et seq."},
       {title: "7", section: "136", section_end: "136y", expected_text: "136–136y"},
       {title: "15", section: "2001", expected_text: "15 U.S.C. 2001"},
       {title: "15", section: "2003", expected_text: "2003"},
       {title: "15", section: "2005", expected_text: "2005"},
       {title: "15", section: "2006", expected_text: "2006"},
       {title: "15", section: "2601", section_end: "2671", expected_text: "2601–2671"},
       {title: "21", section: "331j", expected_text: "21 U.S.C. 331j"},
       {title: "21", section: "346a", expected_text: "346a"},
       {title: "31", section: "9701", expected_text: "31 U.S.C. 9701"},
       {title: "33", section: "1251", expected_text: "33 U.S.C. 1251 et seq."},
       {title: "33", section: "1311", expected_text: "1311"},
       {title: "33", section: "1313d", expected_text: "1313d"},
       {title: "33", section: "1314", expected_text: "1314"},
       {title: "33", section: "1318", expected_text: "1318"},
       {title: "33", section: "1321", expected_text: "1321"},
       {title: "33", section: "1326", expected_text: "1326"},
       {title: "33", section: "1330", expected_text: "1330"},
       {title: "33", section: "1342", expected_text: "1342"},
       {title: "33", section: "1344", expected_text: "1344"},
       {title: "33", section: "1345", paragraph: "(d)", expected_text: "1345 (d) and (e)"},
       {title: "33", section: "1361", expected_text: "1361"},
       {eo_number: 11735},
       {title: "38", section: "21243", expected_text: "38 FR 21243"},
       {title: "3", expected_text: "3 CFR"},
       {title: "42", section: "241", expected_text: "42 U.S.C. 241"},
       {title: "42", section: "242b", expected_text: "242b"},
       {title: "42", section: "243", expected_text: "243"},
       {title: "42", section: "246", expected_text: "246"},
       {title: "42", section: "300f", expected_text: "300f"},
       {title: "42", section: "300g", expected_text: "300g"},
       {title: "42", section: "300g-1", expected_text: "300g–1"},
       {title: "42", section: "300g-2", expected_text: "300g–2"},
       {title: "42", section: "300g-3", expected_text: "300g–3"},
       {title: "42", section: "300g-4", expected_text: "300g–4"},
       {title: "42", section: "300g-5", expected_text: "300g–5"},
       {title: "42", section: "300g-6", expected_text: "300g–6"},
       {title: "42", section: "300j-1", expected_text: "300j–1"},
       {title: "42", section: "300j-2", expected_text: "300j–2"},
       {title: "42", section: "300j-3", expected_text: "300j–3"},
       {title: "42", section: "300j-4", expected_text: "300j–4"},
       {title: "42", section: "300j-9", expected_text: "300j–9"},
       {title: "42", section: "1857", expected_text: "1857 et seq."},
       {title: "42", section: "6901", section_end: "6992k", expected_text: "6901–6992k"},
       {title: "42", section: "7401", section_end: "7671q", expected_text: "7401–7671q"},
       {title: "42", section: "7542", expected_text: "7542"},
       {title: "42", section: "9601", section_end: "9657", expected_text: "9601–9657"},
       {title: "42", section: "11023", expected_text: "11023"},
       {title: "42", section: "11048", expected_text: "11048"}
     ]}
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

    {ex: "14 CFR § 1266.102", citation: {title: "14", section: "1266.102"}},

    {text: "Executive Order 12333", ex: "designated pursuant section 3.5(h) of Executive Order 12333, as amended.", citation: {eo_number: 12333}},

    {ex: "(a) Certain material is incorporated by reference into this part with the approval of the Director of the Federal Register under 5 U.S.C. 552(a) and 1 CFR part 51. The materials listed in this section have the full force of law. All approved material is available for inspection at Office of Pipeline Safety, Pipeline and Hazardous Materials Safety Administration, 1200 New Jersey Avenue SE, Washington, DC 20590, 202-366-4046 <I>https://www.phmsa.dot.gov/pipeline/regs,</I> and is available from the sources listed in the remaining paragraphs of this section. It is also available for inspection at the National Archives and Records Administration (NARA). For information on the availability of this material at NARA, email <I>fedreg.legal@nara.gov</I> or go to <I>www.archives.gov/federal-register/cfr/ibr-locations.html.</I> </P>
    <P>(b) American Petroleum Institute (API), 200 Massachusetts Ave. NW, Suite 1100, Washington, DC 20001, and phone: 202-682-8000, website: <I>https://www.api.org/.</I> ",
     citations: [
       {title: "5", section: "552", paragraph: "(a)"},
       {title: "1", part: "51"}
     ]}
  ]

]

LOREM_PARAGRAPH = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

RSpec.describe ReferenceParser::Cfr do
  include CfrHelper

  describe "per DDH" do # Document Drafting Handbook
    CFR_SCENARIOS.each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end

    def all_non_context_specific_examples
      CFR_SCENARIOS.each_slice(2).map do |description, examples|
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
        result = +""
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
  end

  describe "links CFR" do
    it "issue shorthand usage" do
      expect(
        ReferenceParser.new(only: :cfr, options: {cfr: {slash_shorthand_allowed: true}}).hyperlink(
          "49/147, 150",
          default: {target: nil, class: nil, relative: true}
        )
      ).to eql '<a href="/current/title-49/part-147">49/147</a>, <a href="/current/title-49/part-150">150</a>'
    end
  end
end
