require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "migrated specs" do
    [
      "prior examples", [
        {ex: "10 CFR 100", url_options: {title: "10", part: "100"}},
        {ex: "10 CFR 100.1", url_options: {title: "10", part: "100", section: "1"}},
        {ex: "10 C.F.R. 100.1", url_options: {title: "10", part: "100", section: "1"}},
        {ex: "10 C.F.R. Part 100.1", url_options: {title: "10", part: "100", section: "1"}},
        {ex: "10 C.F.R. parts 100", url_options: {title: "10", part: "100"}},
        {ex: "10 C.F.R. Sec. 100", citation: {title: "10", section: "100"}},
        {ex: "10 CFR 660.71 and 11 CFR 12", url_options: [{title: "10", part: "660", section: "71"},
          {title: "11", part: "12"}]},

        {ex: "10 CFR § 100", citation: {title: "10", section: "100"}},
        {ex: "10 C.F.R. §§ 100", citation: {title: "10", section: "100"}},
        {ex: "10 C.F.R 100.214(a)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)"}},

        {ex: "10 C.F.R 100.214(1)", url_options: {title: "10", part: "100", section: "214", sublocators: "(1)"}},

        {ex: "10 C.F.R 100.214(a)(1)(xiii)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}},
        {ex: "10 C.F.R 100.214 (a) (1) (xiii)", url_options: {title: "10", part: "100", section: "214", sublocators: "(a)(1)(xiii)"}},

        {ex: "10 CFR section 54.506", url_options: {title: "10", part: "54", section: "506", sublocators: nil},
         with_surrounding_text: "10 CFR section 54.506 (see note)"},

        {ex: "49 CFR230.105(c)", url_options: {title: "49", part: "230", section: "105", sublocators: "(c)"}},

        {ex: "12 CFR § 8360.0-7", url_options: {title: "12", part: "8360", section: "0-7"},
         with_surrounding_text: "12 CFR § 8360.0-7 (and see the footnotes)"},

        {ex: "12 CFR Sec 360.0-7(f)", url_options: {title: "12", part: "360", section: "0-7", sublocators: "(f)"}},
        {ex: "12 C.F.R. 9903.201b", url_options: {title: "12", part: "9903", section: "201b", sublocators: nil}},
        {ex: "12 C.F.R. 9903a.201", url_options: {title: "12", part: "9903a", section: "201"}},
        {ex: "12 CFR § 240.10b-21", url_options: {title: "12", part: "240", section: "10b-21"}},
        {ex: "12 CFR § 970-1.1", url_options: {title: "12", part: "970-1", section: "1"}},
        {ex: "12 CFR Part 970-1.3102-02", url_options: {title: "12", part: "970-1", section: "3102-02"}},
        {ex: "12 CFR Part 970-1.3102-02(i)(ii)", url_options: {title: "12", part: "970-1", section: "3102-02", sublocators: "(i)(ii)"}},
        {ex: "12 CFR § 970.3102-05-30-70", url_options: {title: "12", part: "970", section: "3102-05-30-70"}},

        {ex: "12 C.F.R. section 1.1031(a)-1", url_options: {title: "12", part: "1", section: "1031(a)-1", sublocators: nil}},
        {ex: "12 CFR § 240.15c1-1", url_options: {title: "12", part: "240", section: "15c1-1"}},
        {ex: "12 CFR § 275.206(3)-3", url_options: {title: "12", part: "275", section: "206(3)-3"}},
        {ex: "12 CFR § 275.206(a)(3)-3", url_options: {title: "12", part: "275", section: "206(a)(3)-3"}},

        {ex: "12 CFR § 275.206(1)(a)(3)-3(1)", url_options: {title: "12", part: "275", section: "206(1)(a)(3)-3", sublocators: "(1)"}},

        {ex: "15 CFR parts 4 and 903", url_options: [{title: "15", part: "4"},
          {title: "15", part: "903"}]},

        {ex: "33 CFR Parts 160, 161, 164, and 165", url_options: [{title: "33", part: "160"},
          {title: "33", part: "161"},
          {title: "33", part: "164"},
          {title: "33", part: "165"}]},

        {ex: "18 CFR 385.214 or 385.211", url_options: [{title: "18", part: "385", section: "214"},
          {title: "18", part: "385", section: "211"}]},

        {ex: "7 CFR 2.22, 2.80, and 371.3", url_options: [{title: "7", part: "2", section: "22"},
          {title: "7", part: "2", section: "80"},
          {title: "7", part: "371", section: "3"}]}

      ]
    ].each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end
  end
end
