require "spec_helper"

RSpec.describe ReferenceParser::Guesses do
  guessed_numbers_seem_like_a_range_scenarios = {
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

  describe "Paragraph.numbers_seem_like_a_range?" do
    guessed_numbers_seem_like_a_range_scenarios.each do |range, sets_of_numbers|
      description = range ? "range" : "not range"
      describe description do
        sets_of_numbers.each do |numbers|
          it "#{numbers.map(&:to_s).join(",").truncate(48)} is #{description}" do
            expect(!!described_class.numbers_seem_like_a_range?(numbers)).to eq(range)
          end
        end
      end
    end
  end

  guessed_numbers_similarish_scenarios = {
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

  describe "Paragraph.numbers_similarish" do
    guessed_numbers_similarish_scenarios.each do |similar, sets_of_numbers|
      description = similar ? "similar" : "not similar"
      describe description do
        sets_of_numbers.each do |numbers|
          it "#{numbers.map(&:to_s).join(",").truncate(48)} is #{description}" do
            expect(!!described_class.numbers_similarish(numbers)).to eq(similar)
          end
        end
      end
    end
  end
end
