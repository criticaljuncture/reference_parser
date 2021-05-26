require 'spec_helper'

RSpec.describe ReferenceParser::PublicLaw do
  describe "links Public Law" do
    it "example usage" do
      expect(

        ReferenceParser.new(only: :public_law).hyperlink(
          "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.", 
          default: {target: nil, class: nil}
        )

      ).to eql "Lorem ipsum dolor sit amet, <a href='https://www.govinfo.gov/link/plaw/117/public/9'>Public Law 117-9</a> consectetur adipiscing elit."
    end  

    SCENERIOS_PL = [
      { ex:  "Lorem ipsum dolor sit amet, Public Law 117-9 consectetur adipiscing elit.", text: "Public Law 117-9", citation: {congress: 117, law: 9} },
      { ex: ["Public Law 107-295",
             "Pub. Law 107-295",
             "Pub. L. 107-295",
             "P.L. 107-295"], citation: {congress: 107, law: 295} },
    ]

    include RSpecHtmlMatchers

    SCENERIOS_PL.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|        
        it "#{example}" do

          expect(
            ReferenceParser.new(only: :public_law).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenerio[:text] || example,
                             with: { href: executive_order_url(scenerio[:citation]) })

        end
      end
    end  

    def executive_order_url(options)
      ReferenceParser::PublicLaw.new({}).url(options)
    end
  end
end
