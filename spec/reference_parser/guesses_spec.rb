require "spec_helper"

SCENERIOS_GUESSES_NUMBERS_SEEM_LIKE_A_RANGE = {
  true => [
    [1, 2],
    ["1", "2"],
    [0, 1],
    [1, 1],
    [50, 55],
    [7, 12],
    ["50a", "54c"],
    [150, 155],
    [213, 225],
    [5000, 6000],
    [12000, 20000]
  ],
  false => [
    [1, 1000],
    [55, 50],
    [12, 7],
    ["1", "1000"],
    ["50a", "5400c"],
    ["a", "5400c"],
    [225, 213],
    [1, nil]
  ]
}

RSpec.describe ReferenceParser::Guesses do
  describe "Paragraph.numbers_seem_like_a_range?" do
    SCENERIOS_GUESSES_NUMBERS_SEEM_LIKE_A_RANGE.each do |range, sets_of_numbers|
      description = range ? "range" : "not range"
      describe description do
        sets_of_numbers.each do |numbers|
          it "#{numbers.map(&:to_s).join(",").truncate(48)} is #{description}" do
            expect(!!ReferenceParser::Guesses.numbers_seem_like_a_range?(numbers)).to eq(range)
          end
        end
      end
    end
  end
end

SCENERIOS_GUESSES_NUMBERS_SIMILARISH = {
  true => [
    [1, 2, 3, 4],
    ["1", "2", "3", "4"],
    ["5(a)", "5(b)", "6(a)", "6(c)"],
    [1, 2, nil, 4]
  ],
  false => [
    [1, 1000, 50],
    ["1", "1000", "50"],
    ["5(a)", "5(b)", "424242(a)", "6(c)"],
    [1, "1000", nil]
  ]
}

RSpec.describe ReferenceParser::Guesses do
  describe "Paragraph.numbers_similarish" do
    SCENERIOS_GUESSES_NUMBERS_SIMILARISH.each do |similar, sets_of_numbers|
      description = similar ? "similar" : "not similar"
      describe description do
        sets_of_numbers.each do |numbers|
          it "#{numbers.map(&:to_s).join(",").truncate(48)} is #{description}" do
            expect(!!ReferenceParser::Guesses.numbers_similarish(numbers)).to eq(similar)
          end
        end
      end
    end
  end
end
