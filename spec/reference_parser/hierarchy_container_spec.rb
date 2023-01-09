require "spec_helper"

RSpec.describe ReferenceParser::HierarchyContainer do
  slide_likely_paragraph_right_scenarios = {
    "2584.8477(e)-4(a)" => ["2584.8477(e)-4", "(a)"],
    "2584.8477(e)-4(d)(2)" => ["2584.8477(e)-4", "(d)(2)"],
    "31.3401(a)(8)(C)-1(b)" => ["31.3401(a)(8)(C)-1", "(b)"],
    "341.74(c)(5)(iii)" => ["341.74", "(c)(5)(iii)"]
  }

  describe "HierarchyContainer#slide_likely_paragraph_right" do
    slide_likely_paragraph_right_scenarios.each do |section, (expected_section, expected_paragraph)|
      it "splits #{section}" do
        hierarchy = ReferenceParser::Hierarchy.new({section: section.dup}, options: {})
        hierarchy.slide_likely_paragraph_right(:section, :paragraph)

        expect(hierarchy[:section]).to eq(expected_section)
        expect(hierarchy[:paragraph]).to eq(expected_paragraph)
      end
    end
  end
end
