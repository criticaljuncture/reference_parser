require "spec_helper"

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

      # govinfo doesn't want the paragraphs
      { ex: "pursuant to 5 U.S.C. § 5514(a)(2)(D) concerning the", text: "5 U.S.C. § 5514(a)(2)(D)", citation: {title: "5", part: "5514"}, },

      { ex: "16 U.S.C. 470s", citation: {title: "16", part: "470s"}, },
      { ex: "section 802 of title 21 U.S.C", citation: {title: "21", part: "802"}, },
      { ex: "section 802 of title 21 USC", citation: {title: "21", part: "802"}, },
      { ex: "section 802 of title 21 United States Code", citation: {title: "21", part: "802"}, },
      

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


    it "ordering" do
      expect(

        ReferenceParser.new(only: [:usc, :cfr]).hyperlink(
          "is defined in section 802 of title 21 U.S.C.", 
          default: {target: nil, class: nil}
        )
  
      ).to eql "is defined in <a href='https://www.govinfo.gov/link/uscode/21/802'>section 802 of title 21 U.S.C.</a>"
    end    
  end
end
