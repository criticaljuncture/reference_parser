require "spec_helper"

RSpec.describe ReferenceParser::Url do
  describe "links urls" do
    it "example usage" do
      expect(

        ReferenceParser.new(only: :url).hyperlink(
          "Lorem ipsum dolor sit amet, https://example.local consectetur adipiscing elit.", 
          default: {target: nil, class: nil}
        )
  
      ).to eql "Lorem ipsum dolor sit amet, <a href='https://example.local'>https://example.local</a> consectetur adipiscing elit."
    end

    it "w/ an option to ignore" do
      text = "Lorem ipsum dolor sit amet, https://images.example.local consectetur adipiscing elit."
      expect(        

        ReferenceParser.new(only: :url,
          options: {
            url: {
              ignore: -> (citation) {citation[:url]&.start_with?("https://images.example.local")}
            }
          }).hyperlink(text)
  
      ).to eql(text)
    end

    HTML_FRAGMENT = <<-HTML
                    <p class="food">
                      <em>Foo</em>d
                      is good
                    </p>
                    HTML

    SCENERIOS_URL = [
      {ex: "<p>https://a.local www.b.local</p>", result: "<p><a href='https://a.local' class='external'>https://a.local</a> <a href='https://www.b.local' class='external'>www.b.local</a></p>" },
      {ex: "<img src='https://images.null.local/AB01CD23.456/original.gif'/>", result: :no_change},
      {ex: "visit www.example.com", result: "visit <a href='https://www.example.com' class='external'>www.example.com</a>"},
      {ex: "visit www.example.com.", result: "visit <a href='https://www.example.com' class='external'>www.example.com</a>."},
      {ex: HTML_FRAGMENT, result: :no_change},
    ]

    include RSpecHtmlMatchers

    SCENERIOS_URL.each do |scenerio|
      [scenerio[:ex]].flatten.each do |example|        
        it "#{example}" do
          expect(
            ReferenceParser.new().hyperlink(example, default: {target: nil})
          ).to eq((:no_change == scenerio[:result]) ? example : scenerio[:result])
        end
      end
    end
  end
end
