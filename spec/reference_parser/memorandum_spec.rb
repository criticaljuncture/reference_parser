require "spec_helper"

MEMORANDUM_SCENARIOS = [
  {ex: "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961).", text: "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961)", citation: {memorandum: "1961-11-10"}},
  {ex: "Memorandum of the President for Heads of Departments and Agencies (January 1, 2000).", text: "Memorandum of the President for Heads of Departments and Agencies (January 1, 2000)", citation: {memorandum: "2000-01-01"}},
  {ex: "; and Presidential Memorandum of May 11, 2010, ", text: "Presidential Memorandum of May 11, 2010", citation: {memorandum: "2010-05-11"}},
  {ex: "., President's Memorandum of August 21, 1963; 3 CFR, ", text: "President's Memorandum of August 21, 1963", citation: {memorandum: "1963-08-21"}},
  {ex: "Presidential Memorandum entitled “Government Patent Policy”, issued February 18, 1983", citation: {memorandum: "1983-02-18"}},
  {ex: "President's Memorandum to the Attorney General, Delegation of Responsibilities Concerning FBI Employees Under the Civil Service Reform Act of 1978, 3 CFR p. 284 (1997);", expect_slug: :memorandum},
  {ex: "Pres. Mem.", expect_slug: :memorandum},
  {ex: "Presidential Memorandum dated July 8, 2003", citation: {memorandum: "2003-07-08"}}

]

RSpec.describe ReferenceParser::Memorandum do
  describe "optionally links Presidential Memoranda" do
    let(:reference_parser) { ReferenceParser.new(only: :memorandum, options: {include_unlinked: true}) }

    it "example usage" do
      expect(
        reference_parser.hyperlink(
          "Memorandum of the President for Heads of Departments and Agencies (November 10, 1961).",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql '<a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">Memorandum of the President for Heads of Departments and Agencies (November 10, 1961)</a>.'
    end

    MEMORANDUM_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:expect_slug]
            found = []
            reference_parser.each(example) do |citation, slug|
              found << slug
            end
            expect(found).to include(scenario[:expect_slug])
          else
            expect(
              reference_parser.hyperlink(example, default: {target: nil, class: nil})
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: memorandum_url(scenario[:citation])})
          end
        end
      end
    end

    def memorandum_url(options)
      ReferenceParser::Memorandum.new({}).url(options)
    end
  end
end
