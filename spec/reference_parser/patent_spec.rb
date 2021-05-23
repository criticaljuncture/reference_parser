require 'rails_helper'

RSpec.describe ReferenceParser::Patent do
  describe "links Patent Numbers" do
    it 'example usage' do
      expect(

        ReferenceParser.new(only: :patent).hyperlink(
          "Lorem ipsum dolor sit amet, Patent Number 3,005,282 consectetur adipiscing elit.", 
          default: {target: nil, class: nil}
        )

      ).to eql "Lorem ipsum dolor sit amet, <a href='http://patft.uspto.gov/netacgi/nph-Parser?Sect2=PTO1&Sect2=HITOFF&p=1&u=/netahtml/PTO/search-bool.html&r=1&f=G&l=50&d=PALL&RefSrch=yes&Query=PN/3005282'>Patent Number 3,005,282</a> consectetur adipiscing elit."
    end
  end
end
