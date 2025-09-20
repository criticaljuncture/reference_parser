require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "citation aliases" do
    alias_options = {cfr: {allow_aliases: true, best_guess: true, prefer_part: true}}

    [
      "FAR", [
        {ex: "FAR 3", options: alias_options,
         citation: {ambiguous: [
           {title: "14", part: "3"},
           {title: "48", chapter: "1", part: "3"}
         ]}},
        {ex: "FAR Part 3", options: alias_options,
         citation: {ambiguous: [
           {title: "14", part: "3"},
           {title: "48", chapter: "1", part: "3"}
         ]}},
        {ex: "FAR 3.1", options: alias_options,
         citation: {ambiguous: [
           {title: "14", section: "3.1"},
           {title: "48", chapter: "1", section: "3.1"} # does not exist circa 2022-12
         ]}},
        {ex: "FAR 19.1505(d)", options: alias_options,
         citation: {ambiguous: [
           {title: "14", section: "19.1505", paragraph: "(d)"}, # does not exist circa 2022-12
           {title: "48", chapter: "1", section: "19.1505", paragraph: "(d)"}
         ]}},
        {ex: "FAR", options: alias_options,
         citation: {ambiguous: [
           {title: "14"},
           {title: "48", chapter: "1"}
         ]}},
        {ex: "F.A.R", options: alias_options,
         with_surrounding_text: "F.A.R.",
         citation: {ambiguous: [
           {title: "14"},
           {title: "48", chapter: "1"}
         ]}, expected_html: '<a href="/current/title-" class="cfr external">F.A.R</a>.'},
        {ex: "F.A.R. Part 3", options: alias_options,
         citation: {ambiguous: [
           {title: "14", part: "3"},
           {title: "48", chapter: "1", part: "3"}
         ]}},

        {ex: "VAAR 819.70", citation: {title: "48", chapter: "8", section: "819.70"}, options: alias_options},
        {ex: "VAAR Part 819.70", citation: {title: "48", chapter: "8", section: "819.70"}, options: alias_options},
        {ex: "VAAR Subpart 819.70", citation: {title: "48", chapter: "8", subpart: "819.70"}, options: alias_options},
        {ex: "VAAR Section 819.70", citation: {title: "48", chapter: "8", section: "819.70"}, options: alias_options},

        {ex: "DFARS 201.101", citation: {title: "48", chapter: "2", section: "201.101"}, options: alias_options},

        {ex: "41 CFR parts 102-193 and 102-194", citations: [{title: "41", part: "102", part_end: "193"}, {title: "41", part: "102", part_end: "194"}], options: alias_options},
        {ex: "FMR parts 102-193 and 102-194", citations: [{title: "41", part: "102", part_end: "193"}, {title: "41", part: "102", part_end: "194"}], options: alias_options}
      ]
    ].each_slice(2) do |description, examples|
      expect_passing_cfr_scenerios(description, examples)
    end
  end
end
