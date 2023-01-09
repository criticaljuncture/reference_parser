require "spec_helper"

CFR_SCENARIOS = [

  "extracts", [],

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
    {ex: "44 U.S.C. 1506; sec. 6, E.O. 10530, 19 FR 2709; 3 CFR, 1954-1958 Comp., p. 189; 1 U.S.C. 112; 1 U.S.C. 113.",
     citations: [{section: "1506", title: "44"},
       {title: "19", section: "2709"},
       {title: "3"},
       {title: "1", section: "112"},
       {title: "1", section: "113"}],
     expected_html: '<a href="https://www.govinfo.gov/link/uscode/44/1506" class="usc external" target="_blank" rel="noopener noreferrer">44 U.S.C. 1506</a>; sec. 6, E.O. 10530, <a href="/citation/19-FR-2709" class="fr-reference" data-reference="19 FR 2709">19 FR 2709</a>; <a href="/current/title-3" class="cfr external">3 CFR</a>, 1954-1958 Comp., p. 189; <a href="https://www.govinfo.gov/link/uscode/1/112" class="usc external" target="_blank" rel="noopener noreferrer">1 U.S.C. 112</a>; <a href="https://www.govinfo.gov/link/uscode/1/113" class="usc external" target="_blank" rel="noopener noreferrer">1 U.S.C. 113</a>'}
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
  ]

]

LOREM_PARAGRAPH = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

RSpec.describe ReferenceParser::Cfr do
  include CfrHelper

  describe "per DDH" do # Document Drafting Handbook
    CFR_SCENARIOS.each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].to_s.truncate(24)}" do
            expect_passing_cfr_scenerio(example)
          end
        end
      end
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
