require "spec_helper"

SCENERIOS_PARAGRAPH_GUESS_LEVELS = {
  letters: ["(a)", "(bc)", "(zzz)"],
  upper_letters: ["(A)", "(MN)", "(YYY)"],
  romans: ["(i)", "(ix)", "(xvi)"],
  italic_romans: ["(<em>i</em>)", "(<em>ix</em>)", "<em>(xiv)</em>"],
  numbers: ["(1)", "(10)", "(42)"],
  italic_numbers: ["(<em>1</em>)", "(<em>10</em>)", "<em>(42)</em>"]
}

SCENERIOS_PARAGRAPH_GUESS_LEVELS.each

RSpec.describe ReferenceParser::Paragraph do
  describe "Paragraph.guess_level" do
    SCENERIOS_PARAGRAPH_GUESS_LEVELS.each do |level, examples|
      describe level.to_s do
        examples.each do |example|
          it "#{example} is #{level}" do
            expect(ReferenceParser::Paragraph.guess_level(example)).to eq(level)
          end
        end
      end
    end
  end
end
