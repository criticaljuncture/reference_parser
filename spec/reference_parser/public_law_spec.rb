require "spec_helper"

PL_SCENARIOS = [
  {ex: "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.", text: "Public Law 117-9", citation: {congress: 117, law: 9}},
  {ex: "(Pub. L. 107-295)", text: "Pub. L. 107-295", citation: {congress: 107, law: 295}},

  {ex: ["Public Law 107-295",
    "Pub. Law 107-295",
    "Pub. L. 107-295",
    "P.L. 107-295"], citation: {congress: 107, law: 295}},

  {ex: "phone number 202-693-0126 or e-mailed", citation: :expect_none}
]

RSpec.describe ReferenceParser::PublicLaw do
  describe "links Public Law" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :public_law).hyperlink(
          "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.govinfo.gov/link/plaw/117/public/9">Public Law 117-9</a> consectetur adipiscing elit.'
    end

    PL_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:citation] == :expect_none
            expect(
              ReferenceParser.new(only: :public_law).hyperlink(example, default: {target: nil, class: nil})
            ).not_to have_tag("a")
          else
            expect(
              ReferenceParser.new(only: :public_law).hyperlink(example, default: {target: nil, class: nil})
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: public_law_url(scenario[:citation])})
          end
        end
      end
    end

    def public_law_url(options)
      ReferenceParser::PublicLaw.new({}).url(options)
    end
  end
end
