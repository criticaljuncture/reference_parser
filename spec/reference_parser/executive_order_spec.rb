require "spec_helper"

SCENERIOS_EO = [
  {ex: "Lorem ipsum dolor sit amet, Executive Order 14028 consectetur adipiscing elit.", text: "Executive Order 14028", citation: {eo_number: 14028}},
  {ex: ["Executive Order 12944",
    "EO 12944",
    "E. O. 12944",
    "E.O. 12944",
    "Executive Order No 12944",
    "Executive Order No. 12,944"], citation: {eo_number: 12944}}
]

RSpec.describe ReferenceParser::ExecutiveOrder do
  describe "links Executive Orders" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :executive_order).hyperlink(
          "Lorem ipsum dolor sit amet, Executive Order 14028 consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/executive-order/14028" class="external_fr_link" target="_blank" rel="noopener noreferrer">Executive Order 14028</a> consectetur adipiscing elit.'
    end

    SCENERIOS_EO.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :executive_order).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenerio[:text] || example,
                             with: {href: executive_order_url(scenerio[:citation])})
        end
      end
    end

    def executive_order_url(options)
      ReferenceParser::ExecutiveOrder.new({}).url(options)
    end
  end
end
