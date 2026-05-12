require "spec_helper"

USC_SCENERIOS = [
  {ex: "Lorem ipsum dolor sit amet, 12 USC 345 consectetur adipiscing elit.", text: "12 USC 345", citation: {title: 12, part: 345}},
  {ex: ["10 USC 1",
    "10 U.S.C. 1"], citation: {title: 10, part: 1}},
  {ex: "established under section 1506 of title 44, United States Code", text: "section 1506 of title 44, United States Code", citation: {title: "44", part: "1506"}},
  {ex: "under chapter 15 of title 44, United States Code", text: "chapter 15 of title 44, United States Code", citation: {title: "44", part: "1501"}},

  # govinfo doesn't want the paragraphs
  {ex: "pursuant to 5 U.S.C. § 5514(a)(2)(D) concerning the", text: "5 U.S.C. § 5514(a)(2)(D)", citation: {title: "5", part: "5514"}},

  {ex: "16 U.S.C. 470s", citation: {title: "16", part: "470s"}},
  {ex: "section 802 of title 21 U.S.C", citation: {title: "21", part: "802"}},
  {ex: "section 802 of title 21 U.S.C.", citation: {title: "21", part: "802"}},
  {ex: "section 802 of title 21 USC", citation: {title: "21", part: "802"}},
  {ex: "section 802 of title 21 United States Code", citation: {title: "21", part: "802"}},
  {ex: "Section 2381 of Title 22 of the U.S.C.", citation: {title: "22", part: "2381"}},
  {ex: "Section 504, Title 5 U.S.C.", citation: {title: "5", part: "504"}},

  # (#2) /current/title-36/chapter-II/part-228/subpart-A/section-228.2
  {ex: "Act of Congress (16 U.S.C. 482a-482q) is subject", text: "16 U.S.C. 482a-482q", citation: {title: "16", part: "482a", part_end: "482q"}},

  # (#4)
  {ex: "39 U.S.C. 3003, 3004", citations: [{title: "39", part: "3003"}, {title: "39", part: "3004"}]},
  {ex: "16 U.S.C. 482a-482q", citation: {title: "16", part: "482a", part_end: "482q"}},
  {ex: "30 U.S.C. 601, 603, 611-615", citations: [{title: "30", part: "601"},
    {title: "30", part: "603"},
    {title: "30", part: "611", part_end: "615"}]},
  {ex: "23 U.S.C. 107 and 317", citations: [{title: "23", part: "107"}, {title: "23", part: "317"}]},

  {ex: "17 U.S.C. 203, 304(c)", citations: [{title: "17", part: "203"}, {title: "17", part: "304"}], context: "/current/title-37/chapter-II/subchapter-A/part-201/section-201.4"},
  {ex: "17 U.S.C. 203, 304(c) and (d)", citations: [{title: "17", part: "203", expected_url: "https://www.govinfo.gov/link/uscode/17/203"}, {title: "17", part: "304", expected_text: "304(c)", expected_url: "https://www.govinfo.gov/link/uscode/17/304"}], context: "/current/title-37/chapter-II/subchapter-A/part-201/section-201.4"},

  {ex: "(15 U.S.C. 78<em>o</em>(b)(11)(A))", text: "15 U.S.C. 78<em>o</em>(b)(11)(A)", citation: {title: "15", part: "78o"}},
  {ex: "pursuant to section 6(a) of the Act (15 U.S.C. 78f(a)) or a national", text: "15 U.S.C. 78f(a)", citation: {title: "15", part: "78f"}},
  {ex: "(15 U.S.C. 78<em>o</em>-3(a))", text: "15 U.S.C. 78<em>o</em>-3(a)", citation: {title: "15", part: "78o-3"}},

  {ex: "15 U.S.C. 77b, 77b note, 78<em>l,</em> 78m, 78<em>ll</em>(d), 78mm",
   citations: ["77b", "77b", "78l", "78m", "78ll", "78mm"].map { |part| {title: "15", part: part} }},

  {ex: "15 U.S.C. 77c, 77o, 77s, 77z-3, 77sss, 78d, 78d-1, 78d-2, 78o-4, 78w, 78<em>ll</em>(d), 78mm, 80a-37, 80b-11, 7202, and 7211 <em>et seq.,</em> unless otherwise noted. ",
   citations: %w[77c 77o 77s 77z-3 77sss 78d 78d-1 78d-2 78o-4 78w 78ll 78mm 80a-37 80b-11 7202 7211].map { |part| {title: "15", part: part} }},

  {ex: "Sections 200.27 and 200.30-6 are also issued under 15 U.S.C. 77e, 77f, 77g, 77h, 77j, 77q, 77u, 78e, 78g, 78h, 78i, 78k, 78m, 78o, 78o-4, 78q, 78q-1, 78t-1, 78u, 77hhh, 77uuu, 80a-41, 80b-5, and 80b-9.",
   citations: %w[77e 77f 77g 77h 77j 77q 77u 78e 78g 78h 78i 78k 78m 78o 78o-4 78q 78q-1 78t-1 78u 77hhh 77uuu 80a-41 80b-5 80b-9].map { |part| {title: "15", part: part} }},

  {ex: "Section 200.30-1 is also issued under 15 U.S.C. 77f, 77g, 77h, 77j, 78c(b) 78<em>l,</em> 78m, 78n, 78<em>o</em>(d).",
   citations: %w[77f 77g 77h 77j 78c 78l 78m 78n 78o].map { |part| {title: "15", part: part} }},

  {ex: "Section 200.30-3 is also issued under 15 U.S.C. 78b, 78d, 78f, 78k-1, 78q, 78s, and 78eee.",
   citations: %w[78b 78d 78f 78k-1 78q 78s 78eee].map { |part| {title: "15", part: part} }},

  {ex: "Section 200.30-5 is also issued under 15 U.S.C. 77f, 77g, 77h, 77j, 78c(b), 78<em>l,</em> 78m, 78n, 78o(d), 80a-8, 80a-20, 80a-24, 80a-29, 80b-3, 80b-4.",
   citations: %w[77f 77g 77h 77j 78c 78l 78m 78n 78o 80a-8 80a-20 80a-24 80a-29 80b-3 80b-4].map { |part| {title: "15", part: part} }},

  # (#19)
  {ex: "5 U.S.C. 552a(k)(2)",
   citation: {title: "5", part: "552a"}, context: {title: "29", section: "102.119"}},

  # (#19)
  {ex: "5 U.S.C. 552a(b)(1) through (11)",
   citations: [{title: "5", part: "552a"}, {title: "5", part: "552a"}], context: {title: "29", section: "102.18"}},

  # (#19) no results for https://www.govinfo.gov/link/uscode/5/3
  # {ex: "5 U.S.C. App. 3", citation: {title: "5", part: "3"}, context: {title: "39", part: "221"}},

  # (#19)
  {ex: "Internal Revenue Code section 402A(d)(2)", citation: {title: "26", part: "402A"}, context: {title: "5", part: "1605.31"}},

  # (#19)
  {ex: "I.R.C. section 402(g)", citation: {title: "26", part: "402"}, context: {title: "5", part: "1605.11"}},

  # (#19)
  {ex: "5 U.S.C. 5312, 5313, 5314, 5315 or 5316",
   citations: [{title: "5", part: "5312"}, {title: "5", part: "5313"}, {title: "5", part: "5314"}, {title: "5", part: "5315"}, {title: "5", part: "5316"}], context: {title: "5", section: "1603.3", paragraph: "(b)(2)"}},

  # (#20)
  {ex: "defined under 47 U.S.C. 1428(a) and 47 U.S.C. 1442(f).",
   citations: [{title: "47", part: "1428"}, {title: "47", part: "1442"}], context: {title: "47", section: "500.2"}},

  # (#20)
  {ex: "pursuant to 5 U.S.C. 552a(g) and the right",
   citations: [{title: "5", part: "552a"}], context: {title: "5", section: "1630.14"}},

  # (#20)
  {ex: "5 U.S.C. 552(a)", citation: {title: "5", part: "552"}, context: {title: "39", section: "20.1"},
   with_surrounding_text: "5 U.S.C. 552(a) and 1 CFR part 51."},

  # (#20)
  {ex: "Code (26 U.S.C.).", citation: :expect_none},

  # (#20)
  {ex: "I.R.C. § 6212", citation: {title: "26", part: "6212"}, context: {title: "48", section: "9.406-2"},
   with_surrounding_text: "under I.R.C. § 6212, which entitles"},

  {ex: "defined in 5 U.S.C. 2105 and -",
   citations: [{title: "5", part: "2105"}], context: {title: "5", section: "531.203"}},

  {ex: "26 U.S.C. (IRC) 6621,", citations: {title: "26", part: "6621"}},

  {ex: "(7 U.S.C.</em>          §         <em>13 and 18 U.S.C.</em>         §         <em>1001)",
   citations: [{title: "7", part: "13"}, {title: "18", part: "1001"}], context: {title: "17", appendix: "Appendix A to Part 49"}, expect_variance: true},

  {ex: "(15 U.S.C. 80b–3a(a))", citation: {title: "15", part: "80b-3a"}},
  {ex: "42 U.S.C. 290dd–2", citation: {title: "42", part: "290dd-2"}},

  {ex: "5 U.S.C. 5701-11", text: "5 U.S.C. 5701", citation: {title: "5", part: "5701"}, context: {title: "2", part: "200.475"},
   expected_html: '<a href="https://www.govinfo.gov/link/uscode/5/5701">5 U.S.C. 5701</a>-11'}, # 2 CFR 200.475(d)

  {ex: "1 U.S.C. 112a, 112b; and 22 U.S.C. 2651a.", citations: [{title: "1", part: "112a"}, {title: "1", part: "112b"}, {title: "22", part: "2651a"}]},

  {ex: "30 U.S.C. 901 et seq.", citation: {title: "30", part: "901", expected_text: "30 U.S.C. 901 et seq"}},

  {ex: "16 U.S.C. 1a–5, 461 et seq., 463, 1908.", citations: [
    {title: "16", part: "1a", expected_text: "16 U.S.C. 1a–5"}, # part: 1a-5
    {title: "16", part: "461", expected_text: "461 et seq."},
    {title: "16", part: "463", expected_text: "463"},
    {title: "16", part: "1908", expected_text: "1908"}
  ]},

  {ex: "Title 50 U.S.C. 3501 et seq.", citation: {title: "50", part: "3501", expected_text: "50 U.S.C. 3501 et seq"}, expect_variance: true},
  {ex: "10 U.S. Code, Ch. 47, 21 U.S. Code 801, et seq.", citations: [{title: "10", part: "47", expected_text: "10 U.S. Code, Ch. 47", expected_url: "https://www.govinfo.gov/link/uscode/10/4701"}, {title: "21", part: "801 et seq", expected_text: "21 U.S. Code 801, et seq", expected_url: "https://www.govinfo.gov/link/uscode/21/801"}], expect_variance: true},

  {ex: "5 U.S.C. 5514; 5 U.S.C. 5584; 5 U.S.C. 6402; 31 U.S.C. 3701, 3711; 3716, 3717, 3718, 3720A, 3720D.", citations: [
    {title: "5", part: "5514", expected_text: "5 U.S.C. 5514"},
    {title: "5", part: "5584", expected_text: "5 U.S.C. 5584"},
    {title: "5", part: "6402", expected_text: "5 U.S.C. 6402"},
    {title: "31", part: "3701", expected_text: "31 U.S.C. 3701"},
    {title: "31", part: "3711", expected_text: "3711"},
    {title: "31", part: "3716", expected_text: "3716"},
    {title: "31", part: "3717", expected_text: "3717"},
    {title: "31", part: "3718", expected_text: "3718"},
    {title: "31", part: "3720A", expected_text: "3720A"},
    {title: "31", part: "3720D", expected_text: "3720D"}
  ]},

  {ex: "31 U.S.C. 501-06.", citation: {title: "31", part: "501", suffix: "-06", expected_text: "31 U.S.C. 501"}},
  {ex: "40 U.S.C. App. 106.", citation: {title: "40", appendix: "106"}, authority_only: true},
  {ex: "46 App. U.S.C. 1101", citation: {title: "46", appendix: "1101"}, authority_only: true},
  {ex: "46 U.S.C. sections 53902, 53910", citations: [{title: "46", part: "53902"}, {title: "46", part: "53910"}]},

  {
    ex: "authorized by section 8 of the FDIA (12 U.S.C. 1818), sections 15B(c)(5), 15C(c)(2)(B), and 17A(d)(2) of the Exchange Act, and other subparts of this part against the following:",
    expected_url: "https://www.govinfo.gov/link/uscode/12/1818",
    citation: {title: "12", section: "1818"}
  },

  {ex: "46 App. U.S.C. 1171 et seq.; 46 App. U.S.C. 1114 (b), ", citations: [
    {title: "46", appendix: "1171 et seq", authority: "1171 et seq"},
    {title: "46", appendix: "1114"}
  ], authority_only: true},

  {ex: "47 U.S.C. 154(b), (j), (i) and 303(r)", citations: [
    {title: "47", part: "154", expected_text: "47 U.S.C. 154"},
    {title: "47", part: "303", expected_text: "303"}
  ]},

  {ex: "16 U.S.C. 590a-f, 590q, 2005b, 3861, and 3862.", citations: [
    {title: "16", part: "590a", part_end: "f", expected_text: "16 U.S.C. 590a"},
    {title: "16", part: "590q", expected_text: "590q"},
    {title: "16", part: "2005b", expected_text: "2005b"},
    {title: "16", part: "3861", expected_text: "3861"},
    {title: "16", part: "3862", expected_text: "3862"}
  ]},

  {ex: "7 U.S.C. 1308, 1308-1", text: "5 U.S.C. 5701", citations: [
    {title: "7", part: "1308", link: "https://www.govinfo.gov/link/uscode/7/1308-1"},
    {title: "7", part: "1308-1", link: "https://www.govinfo.gov/link/uscode/7/1308-1"}
  ]},

  {ex: "12 U.S.C. 1467a (i) and (r);", text: "12 U.S.C. 1467a", citations: [
    {title: "12", section: "1467a", expected_text: "12 U.S.C. 1467a", link: "https://www.govinfo.gov/link/uscode/12/1467a"}
  ]},

  {ex: "addition to those defined in 12 U.S.C. 5481(15)(A)(i)-(x). The purpose", text: "12 U.S.C. 5481(15)(A)(i)-(x)", citations: [
    {title: "12", section: "5481", expected_text: "12 U.S.C. 5481(15)(A)(i)-(x)", link: "https://www.govinfo.gov/link/uscode/12/5481"}
  ]},

  {ex: "15 U.S.C. 78<em>l</em>(g)", text: "15 U.S.C. 78<em>l</em>(g)", citation: {title: "15", section: "78l", expected_text: "15 U.S.C. 78<em>l</em>", link: "https://www.govinfo.gov/link/uscode/15/78l"}},
  {ex: "15 U.S.C. 78(l)", text: "15 U.S.C. 78(l)", citation: {title: "15", section: "78l", expected_text: "15 U.S.C. 78(l)", link: "https://www.govinfo.gov/link/uscode/15/78l"}},
  {ex: "28 U.S.C. 2461 note;", text: "28 U.S.C. 2461", citation: {title: "28", section: "2461", expected_text: "28 U.S.C. 2461", link: "https://www.govinfo.gov/link/uscode/28/2461"}},
  {ex: "98 Stat. 663, 26 U.S.C. 367; 98 Stat. 993, 26 U.S.C. 927; 98 Stat. 994, 26 U.S.C. 927;", citations: [
    {title: "26", section: "367", expected_text: "26 U.S.C. 367"},
    {title: "26", section: "927", expected_text: "26 U.S.C. 927"},
    {title: "26", section: "927", expected_text: "26 U.S.C. 927"}
  ]},
  {ex: "(Secs. 803 and 805 of the Tax Reform Act of 1984 (98 Stat. 1001) and sec. 7805 of the Internal Revenue Code of 1954 (68A Stat. 917; 26 U.S.C. 7805); sec. 805 (b)(3)(C) and (D) of the Tax Reform Act of 1984 (98 Stat. 1002), and sec. 7805 of the Code (68A Stat. 917; 26 U.S.C. 7805); secs. 367, 927, and 7805 of the Internal Revenue Code of 1954 (98 Stat. 662, 26 U.S.C. 367; 98 Stat. 663, 26 U.S.C. 367; 98 Stat. 993, 26 U.S.C. 927; 98 Stat. 994, 26 U.S.C. 927; and 68A Stat. 917, 26 U.S.C. 7805); sec. 805 of the Tax Reform Act of 1984 (Pub. L. 98-69, 98 Stat. 1000)) ", citations: [
    {title: "26", section: "7805", expected_text: "26 U.S.C. 7805"},
    {title: "26", section: "7805", expected_text: "26 U.S.C. 7805"},
    {title: "26", section: "367", expected_text: "26 U.S.C. 367"},
    {title: "26", section: "367", expected_text: "26 U.S.C. 367"},
    {title: "26", section: "927", expected_text: "26 U.S.C. 927"},
    {title: "26", section: "927", expected_text: "26 U.S.C. 927"},
    {title: "26", section: "7805", expected_text: "26 U.S.C. 7805"}
  ]},

  # references scenarios
  {
    ex: "16 U.S.C. 590a-f", citations: :ignore,
    exempt_reference_keys: [:result, :link, :source, :text],
    expected_references: [
      {title: "16", section: "590a", section_end: "f", suffix: "-f", authority: {section: "590a-f"}, hierarchy: {title: "16", section: "590a", section_end: "f"}, href_hierarchy: {title: "16", part: "590a", section_end: "f"}}
    ]
  },

  {
    ex: "5 U.S.C. app.;", citations: [],
    exempt_reference_keys: [:result, :link, :source, :text],
    expected_references: [
      {title: "5", section: "app", authority: {grouping: "Appendix", section: "App"}, hierarchy: {title: "5", section: "app"}, href_hierarchy: {title: "5", part: "app"}}
    ]
  },

  {ex: "lorem 31 U.S.C. 5151 for ipsum", citation: {title: "31", section: "5151"}, expected_text: "31 U.S.C. 5151"},

  # false positives
  {ex: "authority contained in sections 15B(c)(5), 15C(c)(2)(A), 17A(c)(3), and 17A(c)(4)(C) of the Exchange Act", citation: :expect_none}
]

RSpec.describe ReferenceParser::Usc do
  describe "links" do
    let(:reference_parser) { ReferenceParser.new }
    let(:reference_parser_with_unlinked) { ReferenceParser.new(options: {include_unlinked: true}) }

    it "example usage" do
      expect(
        ReferenceParser.new(only: :usc).hyperlink(
          "Lorem ipsum dolor sit amet, 12 USC 345 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.govinfo.gov/link/uscode/12/345">12 USC 345</a> consectetur adipiscing elit.'
    end

    USC_SCENERIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          unless scenario[:citations] == :ignore
            expected_citations = [scenario[:citation], scenario[:citations]].flatten.compact

            if scenario[:authority_only]
              found = []
              reference_parser_with_unlinked.each(example) do |citation, slug|
                found << citation
              end

              expect(
                found.map { |citation| citation.slice(*expected_citations.first.keys.without(:authority)) }
              ).to eq(expected_citations.map { it.without(:authority) })

              expected_citations.map { it[:authority] }.each_with_index do |authority, index|
                next unless authority.present?
                expect(found[index][:authority]&.values || []).to include(authority)
              end
            end

            result_html = reference_parser.hyperlink(example, default: {target: nil, class: nil})

            if scenario[:authority_only]
              expect(result_html).not_to have_tag("a")
            else
              expect_none = expected_citations.include?(:expect_none)
              link_citations = expected_citations.reject { |citation| citation == :expect_none }

              if expect_none
                expect(result_html).not_to have_tag("a")
              else
                link_citations.each do |citation|
                  href = citation[:expected_url] || citation[:link] || usc_url(citation)

                  if citation[:expected_text]
                    expect_link_with_text(result_html, href: href, text: citation[:expected_text])
                  else
                    expect(
                      result_html
                    ).to have_tag("a", with: {href: href})
                  end
                end

                if link_citations.present?
                  expect(result_html).to have_tag("a", count: link_citations.count)

                  unless scenario[:expect_variance]
                    result_html_text = Nokogiri::HTML.parse(result_html).text
                    example_text = Nokogiri::HTML.parse(example).text
                    expect(
                      result_html_text
                    ).to include(example_text)
                  end
                else
                  expect(result_html).not_to have_tag("a")
                end
              end
            end
          end

          [scenario[:expected_html]].flatten.compact.each do |expected_html|
            expect(result_html).to include(expected_html)
          end

          if scenario[:expected_references].present?
            references = []
            reference_parser_with_unlinked.each(scenario[:ex]) do |reference, source|
              references << reference
            end

            expect_matching_references(references, scenario)
          end
        end
      end
    end

    def usc_url(options)
      options = options.dup
      options[:part] ||= options[:section]
      options[:part].gsub!(" ", "%20") if options[:part]&.to_s&.include?(" ")
      ReferenceParser::Usc.new({}).url(options)
    end

    it "ordering" do
      expect(
        reference_parser.hyperlink(
          "is defined in section 802 of title 21 U.S.C.",
          default: {target: nil, class: nil}
        )
      ).to eql 'is defined in <a href="https://www.govinfo.gov/link/uscode/21/802">section 802 of title 21 U.S.C.</a>'
    end
  end
end
