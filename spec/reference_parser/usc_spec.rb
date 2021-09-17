require "spec_helper"

SCENERIOS_USC = [
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
  {ex: "17 U.S.C. 203, 304(c) and (d)", citations: [{title: "17", part: "203", expected_url: "https://www.govinfo.gov/link/uscode/17/203"}, {title: "17", part: "304", expected_text: "304(c)", expected_url: "https://www.govinfo.gov/link/uscode/17/304"}, {title: "17", part: "304", expected_text: "(d)", expected_url: "https://www.govinfo.gov/link/uscode/17/304"}], context: "/current/title-37/chapter-II/subchapter-A/part-201/section-201.4"},

  {ex: "(15 U.S.C. 78<em>o</em>(b)(11)(A))", text: "15 U.S.C. 78<em>o</em>(b)(11)(A)", citation: {title: "15", part: "78o"}},
  {ex: "pursuant to section 6(a) of the Act (15 U.S.C. 78f(a)) or a national", text: "15 U.S.C. 78f(a)", citation: {title: "15", part: "78f"}},
  {ex: "(15 U.S.C. 78<em>o</em>-3(a))", text: "15 U.S.C. 78<em>o</em>-3(a)", citation: {title: "15", part: "78o-3"}},

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
   citations: [{title: "7", part: "13"}, {title: "18", part: "1001"}], context: {title: "17", appendix: "Appendix A to Part 49"}, expect_variance: true}
]

RSpec.describe ReferenceParser::Usc do
  describe "links USC" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :usc).hyperlink(
          "Lorem ipsum dolor sit amet, 12 USC 345 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql "Lorem ipsum dolor sit amet, <a href='https://www.govinfo.gov/link/uscode/12/345'>12 USC 345</a> consectetur adipiscing elit."
    end

    SCENERIOS_USC.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|
        it example.to_s do
          result_html = ReferenceParser.new.hyperlink(example, default: {target: nil, class: nil})

          citations = [scenerio[:citation], scenerio[:citations]].flatten.compact

          citations.each do |citation|
            next if citation == :expect_none
            if citation[:expected_text]
              expect(
                result_html
              ).to have_tag("a", text: citation[:expected_text], with: {href: citation[:expected_url] || usc_url(citation)})

            else
              expect(
                result_html
              ).to have_tag("a", with: {href: citation[:expected_url] || usc_url(citation)})
            end
          end

          citations.delete(:expect_none)
          if citations.present?
            expect(result_html).to have_tag("a", count: citations.count)

            unless scenerio[:expect_variance]
              result_html_text = Nokogiri::HTML.parse(result_html).text
              example_text = Nokogiri::HTML.parse(example).text
              expect(
                result_html_text
              ).to include(example_text)
            end
          else
            expect(result_html).to_not have_tag("a")
          end
        end
      end
    end

    def usc_url(options)
      ReferenceParser::Usc.new({}).url(options)
    end

    it "ordering" do
      expect(
        ReferenceParser.new(only: [:usc, :cfr]).hyperlink(
          "is defined in section 802 of title 21 U.S.C.",
          default: {target: nil, class: nil}
        )
      ).to eql "is defined in <a href='https://www.govinfo.gov/link/uscode/21/802'>section 802 of title 21 U.S.C.</a>"
    end
  end
end
