require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "migrated specs" do
    [
      "from cfr citation parser spec", [
        # #22
        {ex: "14 CFR Chapter I", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "I"}},
        {ex: "14 CFR Chapter II Subchapter A", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "II", subchapter: "A"}},
        {ex: "14 CFR Part 25", options: {cfr: {best_guess: true}}, citation: {title: "14", part: "25"}},
        {ex: "Title 14 of the CFR", options: {cfr: {best_guess: true}}, citation: {title: "14"}},
        {ex: "2 CFR subtitle A", options: {cfr: {best_guess: true}}, citation: {title: "2", subtitle: "A"}},
        {ex: "14 CFR chapter IV", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "IV"}},
        {ex: "14 CFR chapter IV subchapter Z", options: {cfr: {best_guess: true}}, citation: {title: "14", chapter: "IV", subchapter: "Z"}},
        {ex: "14 CFR part Y subpart Z", options: {cfr: {best_guess: true}}, citation: {title: "14", part: "Y", subpart: "Z"}},

        {ex: "5 CFR 500.5", options: {cfr: {best_guess: true}}, citation: {title: "5", section: "500.5"}},
        {ex: "1 cfr 100", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100"}},
        {ex: "1 cfr 100", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "100"}},
        {ex: "1 c.f.r. 100", options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "1", part: "100"}},
        {ex: "1 c.f.r. 100", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "100"}},
        # {ex: "29 CFR 102, Subpt. B",  options: {cfr: {best_guess: true, prefer_part: true}}, citation: {title: "29", part: "102"}},
        {ex: "29 CFR 102", options: {cfr: {best_guess: true}}, citation: {title: "29", section: "102"}, with_surrounding_text: "29 CFR 102, Subpt. B"},
        {ex: "5 CFR 500.5", options: {cfr: {best_guess: true}}, citation: {title: "5", section: "500.5"}},
        {ex: "8 CFR", options: {cfr: {best_guess: true}}, citation: {title: "8"}},
        {ex: "26 CFR 1.36B-0", options: {cfr: {best_guess: true}}, citation: {title: "26", section: "1.36B-0"}},
        # {ex: "26 CFR 1 3.14",         options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "3.14", }},
        # {ex: "26 CFR 1 Sec. 2-3",     options: {cfr: {best_guess: true}},                    citation: {title: "26", part: "1", section: "2-3", }},
        {ex: "41 CFR 102-118.35", options: {cfr: {best_guess: true}}, citation: {title: "41", section: "102-118.35"}},
        {ex: "41 CFR 102a.35", options: {cfr: {best_guess: true}}, citation: {title: "41", section: "102a.35"}},
        # {ex: "1 CFR 1.505(c)",        options: {cfr: {best_guess: true}},                    citation: {title: "1", section: "1.505(c)", }},
        {ex: "1 CFR 1.25-1T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25-1T"}},
        {ex: "1 CFR 1.25A-1", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25A-1"}},
        {ex: "1 CFR 1.25-1T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.25-1T"}},
        {ex: "1 CFR 1.36B-3T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.36B-3T"}},
        {ex: "1 CFR 1.103(n)-7T", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.103(n)-7T"}},
        {ex: "1 CFR 1.381(c)(18)-1", options: {cfr: {best_guess: true}}, citation: {title: "1", section: "1.381(c)(18)-1"}},
        {ex: "1 CFR", options: {cfr: {best_guess: true}}, citation: {title: "1"}, with_surrounding_text: "1 CFR Food"}
      ]
    ].each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end
  end
end
