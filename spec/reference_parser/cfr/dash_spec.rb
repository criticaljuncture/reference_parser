require "spec_helper"

RSpec.describe "ReferenceParser::Cfr" do
  include CfrHelper

  describe "extracts" do
    [
      "en dash", [
        {ex: "§ 1.199A–12", context: {composite_hierarchy: "26::I:A:1::1.199A-8"},
         with_surrounding_text: "see § 1.199A–12.",
         citation: {title: "26", section: "1.199A-12", expected_url: "/current/title-26/section-1.199A-12"}},

        {ex: "§ 1.861–20(d)(2)(ii)(B) and (C)", context: {composite_hierarchy: "26::I:A:1::1.245A(d)-1"},
         with_surrounding_text: "residual groupings under § 1.861–20(d)(2)(ii)(B) and (C) without regard to",
         citations: [
           {title: "26", section: "1.861-20", paragraph: "(d)(2)(ii)(B)", expected_url: "/current/title-26/section-1.861-20#p-1.861-20(d)(2)(ii)(B)"},
           {title: "26", section: "1.861-20", paragraph: "(d)(2)(ii)(C)", expected_url: "/current/title-26/section-1.861-20#p-1.861-20(d)(2)(ii)(C)"}
         ]}
      ],
      "em dash", [
        {ex: "§ 1.199A—12", context: {composite_hierarchy: "26::I:A:1::1.199A-8"},
         with_surrounding_text: "see § 1.199A—12.",
         citation: {title: "26", section: "1.199A-12", expected_url: "/current/title-26/section-1.199A-12"}}
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

  describe "permute" do
    [
      {ex: "lorem", expected: ["lorem"]},
      {ex: "lorem ipsum", expected: ["lorem ipsum"]},
      {ex: "lorem-ipsum", expected: ["lorem-ipsum", "lorem–ipsum", "lorem—ipsum"]},
      {ex: "lorem–ipsum", expected: ["lorem-ipsum", "lorem–ipsum", "lorem—ipsum"]},
      {ex: "lorem—ipsum", expected: ["lorem-ipsum", "lorem–ipsum", "lorem—ipsum"]},
      {ex: "a-b-c", expected: ["a-b-c", "a-b–c", "a-b—c", "a–b-c", "a–b–c", "a–b—c", "a—b-c", "a—b–c", "a—b—c"]},
      {ex: "a-b-c-d", expected_count: 27},
      {ex: "a-b-c-d-e", expected_count: 81},
      {ex: "a-b-c-d-e-f", expected_count: 1, expected: ["a-b-c-d-e-f"]},
      {ex: "a-b-c", max_occurrences: 1, expected: ["a-b-c"]}
    ].each do |scenerio|
      it "permutes #{scenerio[:ex]}" do
        permuted = if scenerio[:max_occurrences]
          ReferenceParser::Dashes.permute(scenerio[:ex], max_occurrences: scenerio[:max_occurrences])
        else
          ReferenceParser::Dashes.permute(scenerio[:ex])
        end

        expect(permuted).to eq(Set.new(scenerio[:expected])) if scenerio[:expected]
        expect(permuted.count).to eq(scenerio[:expected_count]) if scenerio[:expected_count]
      end
    end
  end
end
