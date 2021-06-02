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
  {ex: "section 802 of title 21 USC", citation: {title: "21", part: "802"}},
  {ex: "section 802 of title 21 United States Code", citation: {title: "21", part: "802"}},

  # (#4)
  {ex: "39 U.S.C. 3003, 3004", citations: [{title: "39", part: "3003"}, {title: "39", part: "3004"}]},
  {ex: "16 U.S.C. 482a-482q", citation: {title: "16", part: "482a", part_end: "482q"}},
  {ex: "30 U.S.C. 601, 603, 611-615", citations: [{title: "30", part: "601"},
    {title: "30", part: "603"},
    {title: "30", part: "611", part_end: "615"}]},
  {ex: "23 U.S.C. 107 and 317", citations: [{title: "23", part: "107"}, {title: "23", part: "317"}]},

  {ex: "17 U.S.C. 203, 304(c)", citations: [{title: "17", part: "203"}, {title: "17", part: "304"}], context: "/current/title-37/chapter-II/subchapter-A/part-201/section-201.4"}
  # { ex: "17 U.S.C. 203, 304(c) and (d)", citations: [{title: "17", part: "203"}, {title: "17", part: "304"}, {title: "17", part: "304"}], context: "/current/title-37/chapter-II/subchapter-A/part-201/section-201.4"},
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
          result_html = ReferenceParser.new(only: :usc).hyperlink(example, default: {target: nil, class: nil})

          citations = [scenerio[:citation], scenerio[:citations]].flatten.compact

          if citations == 1

            expect(
              result_html
            ).to have_tag("a", text: scenerio[:text] || example,
                               with: {href: usc_url(citation)})

          else

            citations.each do |citation|
              expect(
                result_html
              ).to have_tag("a", with: {href: usc_url(citation)})
            end

            expect(result_html).to have_tag("a", count: citations.count)

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
