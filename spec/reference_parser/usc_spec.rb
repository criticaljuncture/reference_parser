require "rails_helper"

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

    SCENERIOS_RP = [
      { ex:  "Lorem ipsum dolor sit amet, 12 USC 345 consectetur adipiscing elit.", text: "12 USC 345", citation: {title: 12, part: 345} },
      { ex: ["10 USC 1",
             "10 U.S.C. 1"], citation: {title: 10, part: 1} },
      { ex: "established under section 1506 of title 44, United States Code", text: "section 1506 of title 44, United States Code", citation: {title: "44", part: "1506"}, },
      { ex: "under chapter 15 of title 44, United States Code", text: "chapter 15 of title 44, United States Code", citation: {title: "44", part: "1501"}, },
    ]

    include RSpecHtmlMatchers

    SCENERIOS_RP.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|        
        it "#{example}" do

          expect(
            ReferenceParser.new(only: :usc).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenerio[:text] || example,
                             with: { href: usc_url(scenerio[:citation]) })

        end
      end
    end
    
    def usc_url(options)
      ReferenceParser::Usc.new({}).url(options)
    end
  end
end
