require "spec_helper"

EMAIL_SCENARIOS = [
  {ex: "part by email to <em>FOIA@example.local</em> or in writing ", text: "FOIA@example.local", href: "mailto:FOIA@example.local"},
  {ex: "email at <em>ogis@example.local,</em> or via the telephone", text: "ogis@example.local", href: "mailto:ogis@example.local"},
  {ex: "contact robot@example.com", result: 'contact <a href="mailto:robot@example.com" class="email">robot@example.com</a>'},
  {ex: "or e-mailed to OLMS-TransitGrant@dol.gov.", result: 'or e-mailed to <a href="mailto:OLMS-TransitGrant@dol.gov" class="email">OLMS-TransitGrant@dol.gov</a>.'},
  {ex: "Email: <em>orders@example.com.</em>", result: 'Email: <em><a href="mailto:orders@example.com" class="email">orders@example.com</a>.</em>'}
]

RSpec.describe ReferenceParser::Email do
  describe "email urls" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :email).hyperlink(
          "Lorem ipsum dolor sit amet, contact robot@example.local consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, contact <a href="mailto:robot@example.local" class="email">robot@example.local</a> consectetur adipiscing elit.'
    end

    EMAIL_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          if scenario[:result]
            expect(
              ReferenceParser.new.hyperlink(example, default: {target: nil})
            ).to eq((scenario[:result] == :no_change) ? example : scenario[:result])
          end
          if scenario[:href]
            expect(
              ReferenceParser.new.hyperlink(example, default: {target: nil})
            ).to have_tag("a", text: scenario[:text] || example,
              with: {href: scenario[:href]})

          end
        end
      end
    end
  end
end
