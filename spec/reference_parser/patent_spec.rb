require "spec_helper"

RSpec.describe ReferenceParser::Patent do
  describe "links Patent Numbers" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :patent).hyperlink(
          "Lorem ipsum dolor sit amet, Patent Number 3,005,282 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="http://patft.uspto.gov/netacgi/nph-Parser?Sect2=PTO1&amp;Sect2=HITOFF&amp;p=1&amp;u=/netahtml/PTO/search-bool.html&amp;r=1&amp;f=G&amp;l=50&amp;d=PALL&amp;RefSrch=yes&amp;Query=PN/3005282">Patent Number 3,005,282</a> consectetur adipiscing elit.'
    end
  end
end
