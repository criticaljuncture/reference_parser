require "spec_helper"

DETERMINATION_SCENARIOS = [
  {ex: "Lorem ipsum dolor sit amet; Presidential Determination 2003-23, consectetur adipiscing elit.", text: "Presidential Determination 2003-23", citation: {determination: "2003-23"}},
  {ex: ["Presidential Determination 2003-23",
    "Presidential Determination No. 2003-23",
    "Presidential Determination No 2003-23"], citation: {determination: "2003-23"}}
]

RSpec.describe ReferenceParser::Determination do
  describe "optionally links Presidential Determinations" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :determination).hyperlink(
          "Lorem ipsum dolor sit amet; Presidential Determination 2003-23, consectetur adipiscing elit.",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'Lorem ipsum dolor sit amet; <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Presidential Determination 2003-23</a>, consectetur adipiscing elit.'
    end

    DETERMINATION_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :determination).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: determination_url(scenario[:citation])})
        end
      end
    end

    def determination_url(options)
      ReferenceParser::Determination.new({}).url(options)
    end
  end
end
