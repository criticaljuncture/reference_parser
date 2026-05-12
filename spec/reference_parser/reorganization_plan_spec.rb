require "spec_helper"

REORGANIZATION_PLAN_SCENARIOS = [
  {
    ex: "; 1946 Reorganization Plan No. 2, sec. 3,",
    text: "1946 Reorganization Plan No. 2",
    citation: {reorganization_plan: "1946 Plan No. 2"}
  },
  {
    ex: "; Reorganization Plan No. 19 of 1950, sec. 1,",
    text: "Reorganization Plan No. 19 of 1950",
    citation: {reorganization_plan: "1950 Plan No. 19"}
  },
  {ex: "1946 Reorganization Plan No 2", citation: {reorganization_plan: "1946 Plan No. 2"}},
  {ex: "Reorganization Plan No 19 of 1950", citation: {reorganization_plan: "1950 Plan No. 19"}}
]

RSpec.describe ReferenceParser::ReorganizationPlan do
  describe "optionally links Reorganization Plans" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :reorganization_plan).hyperlink(
          "; 1946 Reorganization Plan No. 2, sec. 3,",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql '; <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">1946 Reorganization Plan No. 2</a>, sec. 3,'
    end

    REORGANIZATION_PLAN_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :reorganization_plan).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: reorganization_plan_url(scenario[:citation])})
        end
      end
    end

    def reorganization_plan_url(options)
      ReferenceParser::ReorganizationPlan.new({}).url(options)
    end
  end
end
