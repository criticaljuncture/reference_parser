require "spec_helper"

SCENERIOS_PGI = [
  {ex: "See PGI 215.404-2 for guidance.", text: "PGI 215.404-2", citation: {page: "215.4", anchor_suffix: "04-2"},
   url: "https://www.acq.osd.mil/dpap/dars/dfars/html/current/215_4.htm#215.404-2"}
]

RSpec.describe ReferenceParser::DfarsPgi do
  describe "links DFARS/PGI" do
    SCENERIOS_PGI.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|
        it example.to_s do
          if scenerio[:citation] == :expect_none
            expect(
              ReferenceParser.new(only: :dfars_pgi).hyperlink(example, default: {target: nil, class: nil})
            ).not_to have_tag("a")
          else
            expect(
              ReferenceParser.new(only: :dfars_pgi).hyperlink(example, default: {target: nil, class: nil})
            ).to have_tag("a", text: scenerio[:text] || example,
                               with: {href: described_class.new({}).url(scenerio[:citation])})
          end
        end
      end
    end
  end
end
