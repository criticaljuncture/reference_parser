require "spec_helper"

SCENERIOS_RIN = [
  {ex: "See RIN 1234-AB12 and RIN 1234-AB34.", citations: [{rin: "1234-AB12"}, {rin: "1234-AB34"}], result: 'See <a href="/r/1234-AB12">RIN 1234-AB12</a> and <a href="/r/1234-AB34">RIN 1234-AB34</a>.'}
]

RSpec.describe ReferenceParser::RegulatoryPlan do
  describe "links Regulatory Plans" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :regulatory_plan).hyperlink(
          "Lorem ipsum dolor sit amet, RIN 8888-AB88 consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/r/8888-AB88" class="external_fr_link" target="_blank" rel="noopener noreferrer">RIN 8888-AB88</a> consectetur adipiscing elit.'
    end

    SCENERIOS_RIN.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|
        it example.to_s do
          result = ReferenceParser.new(only: :regulatory_plan).hyperlink(example, default: {target: nil, class: nil})
          (scenerio[:citations] || [scenerio[:citation]]).each do |citation|
            expect(
              result
            ).to have_tag("a", text: "RIN #{citation[:rin]}" || example,
                               with: {href: regulatory_plan_url(citation)})
          end
        end
      end
    end

    def regulatory_plan_url(options)
      ReferenceParser::RegulatoryPlan.new({}).url(options)
    end
  end
end
