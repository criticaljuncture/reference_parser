require "spec_helper"

PGI_SCENARIOS = [
  {ex: "See PGI 215.404-2 for guidance.", text: "PGI 215.404-2", citation: {page: "215.4", anchor_suffix: "04-2"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-2"},
  {ex: "See PGI 215.404–2 for guidance.", text: "PGI 215.404–2", citation: {page: "215.4", anchor_suffix: "04-2"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-2"},
  {ex: "procedures at PGI 215.404-1 for proposal analysis", text: "PGI 215.404-1", citation: {page: "215.4", anchor_suffix: "04-1"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-1"},
  {ex: "(see PGI 215.404-1(b)(v))", text: "PGI 215.404-1", citation: {page: "215.4", anchor_suffix: "04-1"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-1"},
  {ex: "See PGI 215.404-71-4(c) for obtaining", text: "PGI 215.404-71-4", citation: {page: "215.4", anchor_suffix: "04-71-4"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-71-4"}
]

RSpec.describe ReferenceParser::DfarsPgi do
  describe "links DFARS/PGI" do
    PGI_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:citation] == :expect_none
            expect(
              ReferenceParser.new(only: :dfars_pgi).hyperlink(example, default: {target: nil, class: nil})
            ).not_to have_tag("a")
          else
            expect(
              ReferenceParser.new(only: :dfars_pgi).hyperlink(example, default: {target: nil, class: nil})
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: described_class.new({}).url(scenario[:citation])})
          end
        end
      end
    end
  end
end
