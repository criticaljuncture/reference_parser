require "spec_helper"

EO_SCENARIOS = [
  {ex: "Lorem ipsum dolor sit amet, Executive Order 14028 consectetur adipiscing elit.", text: "Executive Order 14028", citation: {eo_number: 14028}},
  {ex: ["Executive Order 12944",
    "EO 12944",
    "E. O. 12944",
    "E.O. 12944",
    "E.O.12944",
    "E.0. 12944",
    "Exec. Order 12944",
    "Executive Order No 12944",
    "Executive Order No. 12,944"], citation: {eo_number: 12944}},
  {ex: "Executive order of October 7, 2022.", expect_slug: :eo},
  {ex: "and under Executive Orders 11034 and 12048, ", citations: [{eo_number: 11034}, {eo_number: 12048}]},
  {ex: "Executive Orders 11034, 12048", citations: [{eo_number: 11034}, {eo_number: 12048}]},
  {ex: "E.O. 11034 and 12048", citations: [{eo_number: 11034}, {eo_number: 12048}]},
  {text: "Executive Order 12333", ex: "designated pursuant section 3.5(h) of Executive Order 12333, as amended.", citation: {eo_number: 12333}}
]

RSpec.describe ReferenceParser::ExecutiveOrder do
  describe "links Executive Orders" do
    let(:reference_parser) { ReferenceParser.new(only: :executive_order, options: {include_unlinked: true}) }

    it "example usage" do
      expect(
        reference_parser.hyperlink(
          "Lorem ipsum dolor sit amet, Executive Order 14028 consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/executive-order/14028" class="external_fr_link" target="_blank" rel="noopener noreferrer">Executive Order 14028</a> consectetur adipiscing elit.'
    end

    EO_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:expect_slug]
            found = []
            reference_parser.each(example) do |citation, slug|
              found << slug
            end
            expect(found).to include(scenario[:expect_slug])
          else
            result_html = reference_parser.hyperlink(example, default: {target: nil, class: nil})

            citations = [scenario[:citation], scenario[:citations]].flatten.compact

            if citations.size == 1
              expect(
                result_html
              ).to have_tag("a", text: scenario[:text] || example,
                with: {href: executive_order_url(citations.first)})
            else
              citations.each do |citation|
                expect(
                  result_html
                ).to have_tag("a", with: {href: executive_order_url(citation)})
              end

              expect(result_html).to have_tag("a", count: citations.count)
            end
          end
        end
      end
    end

    def executive_order_url(options)
      ReferenceParser::ExecutiveOrder.new({}).url(options)
    end
  end
end
