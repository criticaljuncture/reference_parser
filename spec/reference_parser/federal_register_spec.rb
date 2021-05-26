require 'spec_helper'

RSpec.describe ReferenceParser::FederalRegister do
  describe "links Federal Register" do
    it 'example usage' do
      expect(

        ReferenceParser.new(only: :federal_register).hyperlink(
          "Lorem ipsum dolor sit amet, 60 FR 1000 consectetur adipiscing elit.", 
          default: {target: nil, class: nil}
        )

      ).to eql "Lorem ipsum dolor sit amet, <a href='https://www.federalregister.gov/citation/60-FR-1000' data-reference='60 FR 1000'>60 FR 1000</a> consectetur adipiscing elit."
    end
    
    it 'relative urls' do
      expect(

        ReferenceParser.new(only: :federal_register).hyperlink(
          "Lorem ipsum dolor sit amet, 60 FR 1000 consectetur adipiscing elit.", 
          default: {target: nil, class: nil, relative: true}
        )

      ).to eql "Lorem ipsum dolor sit amet, <a href='/citation/60-FR-1000' data-reference='60 FR 1000'>60 FR 1000</a> consectetur adipiscing elit."
    end
  end
end
