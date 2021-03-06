require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "fuzzy matches" do
    [
      "buest guess / suggestions", [
        {ex: "Title 14 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", section: "1266.102"}},
        {ex: "Title 14 Chapter V Part 1266 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102"}},
        {ex: "Title 1 Chapter I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
        {ex: "Title 1 Chap I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
        {ex: "Title 1 Ch I Subch B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
        {ex: "14 Chapter V Part 1266 § 1266.102", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", chapter: "V", part: "1266", section: "1266.102"}},
        {ex: "1 Chapter I Subchapter B", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", chapter: "I", subchapter: "B"}},
        {ex: "14/1266", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "14", part: "1266"}},
        {ex: "41 CFR subpart 101-19.6", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "41", subpart: "101-19.6"}},
        {ex: "21 558.128", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "21", section: "558.128"}},
        {ex: "48 CFR Supbart 816.70", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "48", subpart: "816.70"}},
        {ex: "48 CFR Ch. 7, Appendix D", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "48", chapter: "7", appendix: "D"}},
        {ex: "50 CFR Table 1b to Part 660, Subpart C", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "50", part: "660", subpart: "C", table: "1b"},
         expected_url: "/current/title-50/part-660/subpart-C/appendix-Table%201b%20to%20Part%20660,%20Subpart%20C"},
        {ex: "09 CFR 75.4", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "9", section: "75.4"}},
        {ex: "40 Part 63", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "40", part: "63"}}
        # Citations
        # {ex: "Appendix J to Part 50, Title 10", citation: {title: "10", part: "50", appendix: "J"},
        #  expected_url: "/current/title-10/chapter-I/part-50/appendix-Appendix%20J%20to%20Part%2050"}
      ]
    ].each_slice(2) do |description, examples|
      describe description do
        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].to_s.truncate(24)}" do
            test_cfr_scenerio(example)
          end
        end
      end
    end
  end
end
