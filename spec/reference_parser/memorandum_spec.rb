require "spec_helper"

MEMORANDUM_SCENARIOS = [
  {ex: "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961).", text: "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961)", citation: {memorandum: "1961-11-10"}},
  {ex: "Memorandum of the President for Heads of Departments and Agencies (January 1, 2000).", text: "Memorandum of the President for Heads of Departments and Agencies (January 1, 2000)", citation: {memorandum: "2000-01-01"}},
  {ex: "; and Presidential Memorandum of May 11, 2010, ", text: "Presidential Memorandum of May 11, 2010", citation: {memorandum: "2010-05-11"}}
]

RSpec.describe ReferenceParser::Memorandum do
  describe "optionally links Presidential Memoranda" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :memorandum).hyperlink(
          "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961).",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql '<a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Memorandum of the President for Heads of Departments and Agencies (November 10, 1961)</a>.'
    end

    MEMORANDUM_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :memorandum).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: memorandum_url(scenario[:citation])})
        end
      end
    end

    def memorandum_url(options)
      ReferenceParser::Memorandum.new({}).url(options)
    end
  end
end
