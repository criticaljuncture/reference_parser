require "spec_helper"

RSpec.describe ReferenceParser::Email do
  describe "email urls" do
    it "example usage" do
      expect(

        ReferenceParser.new(only: :email).hyperlink(
          "Lorem ipsum dolor sit amet, contact robot@example.local consectetur adipiscing elit.", 
          default: {target: nil, class: nil}
        )
  
      ).to eql "Lorem ipsum dolor sit amet, contact <a href='mailto:robot@example.local' class='email'>robot@example.local</a> consectetur adipiscing elit."
    end

    SCENERIOS_EMAIL = [
      {ex: "part by email to <em>FOIA@example.local</em> or in writing ", text: "FOIA@example.local", href: "mailto:FOIA@example.local"},
      {ex: "email at <em>ogis@example.local,</em> or via the telephone", text: "ogis@example.local", href: "mailto:ogis@example.local"},
      {ex: "contact robot@example.com", result: "contact <a href='mailto:robot@example.com' class='email'>robot@example.com</a>"},
    ]

    include RSpecHtmlMatchers

    SCENERIOS_EMAIL.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|        
        it "#{example}" do
          if scenerio[:result]
            expect(
              ReferenceParser.new().hyperlink(example, default: {target: nil})
            ).to eq((:no_change == scenerio[:result]) ? example : scenerio[:result])
          end
          if scenerio[:href]
            expect(
              ReferenceParser.new().hyperlink(example, default: {target: nil})
            ).to have_tag("a", text: scenerio[:text] || example,
                               with: {href: scenerio[:href]})

          end          
        end
      end
    end
  end  
end
