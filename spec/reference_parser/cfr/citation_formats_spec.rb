require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper
  describe "observed citation formats" do
    [
      "bluebook", [
        {ex: "12 C.F.R. pt. 220", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "12", part: "220"}, expected_url: "/current/title-12/part-220"},
        {ex: "12 C.F.R. pt. 220", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "12", part: "220"}, optional: [:chapter], expected_url: "/current/title-12/part-220",
         with_surrounding_text: "12 C.F.R. pt. 220 (2014)"}
      ]
    ].each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].to_s.truncate(24)}" do
            expect_passing_cfr_scenerio(example)
          end
        end
      end
    end
  end
end
