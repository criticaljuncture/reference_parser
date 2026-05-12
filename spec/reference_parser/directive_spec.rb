require "spec_helper"

DIRECTIVE_SCENARIOS = [
  {
    ex: "E.O. 11652 (37 FR 5209, National Security Council Directive of May 17, 1972 (37 FR 10053).",
    text: "National Security Council Directive of May 17, 1972",
    citation: {directive: "1972-05-17"}
  },
  {ex: "National Security Council Directive of May 17, 1972", citation: {directive: "1972-05-17"}},
  {ex: "National Security Council Directive of January 1, 2000", citation: {directive: "2000-01-01"}},
  {ex: "National Security Council Directive of Jan 17, 1972", citation: {directive: "1972-01-17"}},
  {ex: "National Security Council Directive of Jan. 17, 1972", citation: {directive: "1972-01-17"}},
  {ex: "and the National Security Directive of May 17, 1972 (", text: "National Security Directive of May 17, 1972", citation: {directive: "1972-05-17"}},

  {
    ex: ", and National Security Decision Directive 84, “Safeguarding National Security Information,” signed by the President on March 11, 1983 (hereafter referred to as NSDD 84).",
    text: "National Security Decision Directive 84, “Safeguarding National Security Information,” signed by the President on March 11, 1983",
    citation: {directive: "84", date: "1983-03-11"}
  }
]

RSpec.describe ReferenceParser::Directive do
  describe "optionally links National Security Council Directives" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :directive).hyperlink(
          "E.O. 11652 (37 FR 5209, National Security Council Directive of May 17, 1972 (37 FR 10053).",
          default: {target: "_blank", class: "external_fr_link"}
        )
      ).to eql 'E.O. 11652 (37 FR 5209, <a href="#" class="external_fr_link" target="_blank" rel="noopener noreferrer">National Security Council Directive of May 17, 1972</a> (37 FR 10053).'
    end

    DIRECTIVE_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          expect(
            ReferenceParser.new(only: :directive).hyperlink(example, default: {target: nil, class: nil})
          ).to have_tag("a", text: scenario[:text] || example,
            with: {href: directive_url(scenario[:citation])})
        end
      end
    end

    def directive_url(options)
      ReferenceParser::Directive.new({}).url(options)
    end
  end
end
