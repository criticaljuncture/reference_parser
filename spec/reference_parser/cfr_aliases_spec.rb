require "spec_helper"

ALTERNATE_REFERENCE_SCENARIOS = {
  "generic" => [
    {citation: "48 CFR 1.105-2", alternate: "FAR 1.105-2", overlay: :none, overlay_link: :none, hierarchy: {title: "48", chapter: "1", section: "1.105-2"}},
    {citation: "48 CFR 814.202-4", alternate: "VAAR 814.202-4", overlay: "48 CFR 14.202-4", overlay_link: '<a href="/current/title-48/section-14.202-4" class="cfr external">48 CFR 14.202-4</a>', hierarchy: {title: "48", chapter: "8", section: "814.202-4"}},
    {citation: "48 CFR 3006.302-1", alternate: "HSAR 3006.302-1", overlay: "48 CFR 6.302-1", overlay_link: '<a href="/current/title-48/section-6.302-1" class="cfr external">48 CFR 6.302-1</a>', hierarchy: {title: "48", chapter: "30", section: "3006.302-1"}}
  ],
  "avoid repeating alias portion" => [
    {citation: "48 CFR Chapter 2", alternate: "DFARS", overlay: :none, overlay_link: :none, hierarchy: {title: "48", chapter: "2"}},
    {citation: "48 CFR Chapter 2 Subchapter A", alternate: "DFARS Subchapter A", overlay: :none, overlay_link: :none, hierarchy: {title: "48", chapter: "2", subchapter: "A"}},
    {citation: "48 CFR Part 201", alternate: "DFARS Part 201", overlay: "48 CFR Part 1", overlay_link: '<a href="/current/title-48/part-1" class="cfr external">48 CFR Part 1</a>', hierarchy: {title: "48", chapter: "2", subchapter: "A", part: "201"}},
    {citation: "48 CFR Subpart 201.1", alternate: "DFARS Subpart 201.1", overlay: "48 CFR Subpart 1.1", overlay_link: '<a href="/current/title-48/subpart-1.1" class="cfr external">48 CFR Subpart 1.1</a>', hierarchy: {title: "48", chapter: "2", subchapter: "A", part: "201", subpart: "201.1"}}
  ],
  "structure" => [
    {citation: "48 CFR Part 631", alternate: "DOSAR Part 631", overlay: "48 CFR Part 31", overlay_path: "/current/title-48/part-31", overlay_link: '<a href="/current/title-48/part-31" class="cfr external">48 CFR Part 31</a>', hierarchy: {title: "48", chapter: "6", part: "631"}},
    {citation: "48 CFR Part 631", alternate: "DOSAR Part 631", overlay: "48 CFR Part 31", overlay_path: "/current/title-48/part-31", overlay_link: '<a href="/current/title-48/part-31" class="cfr external">48 CFR Part 31</a>', hierarchy: {title: 48, chapter: "6", part: "631"}},
    {citation: "48 CFR Subpart 631.1", alternate: "DOSAR Subpart 631.1", overlay: "48 CFR Subpart 31.1", overlay_path: "/current/title-48/subpart-31.1", overlay_link: '<a href="/current/title-48/subpart-31.1" class="cfr external">48 CFR Subpart 31.1</a>', hierarchy: {title: "48", chapter: "6", part: "631", subpart: "631.1"}},
    {citation: "48 CFR 631.101", alternate: "DOSAR 631.101", overlay: "48 CFR 31.101", overlay_path: "/current/title-48/section-31.101", overlay_link: '<a href="/current/title-48/section-31.101" class="cfr external">48 CFR 31.101</a>', hierarchy: {title: "48", chapter: "6", section: "631.101"}},
    {citation: "48 CFR 600", alternate: "DOSAR Part 600", overlay: :none, overlay_link: :none, hierarchy: {title: "48", chapter: "6", part: "600"}}
  ]
}

RSpec.describe ReferenceParser::CfrAliases do
  ALTERNATE_REFERENCE_SCENARIOS.each do |description, scenarios|
    describe "CFR aliases & overlays (#{description})" do
      scenarios.each do |scenerio|
        it "recognizes #{scenerio[:citation]}" do
          if scenerio[:alternate]
            expect(
              ReferenceParser::Cfr.alternate_reference_for(scenerio[:hierarchy])
            ).to eq(scenerio[:alternate])
          end

          if scenerio[:overlay] || scenerio[:overlay_path]
            overlay = ReferenceParser::Cfr.overlay_for(scenerio[:hierarchy])
            if scenerio[:overlay]
              if scenerio[:overlay] == :none
                expect(overlay).to be_nil
              else
                expect(overlay).to eq(scenerio[:overlay])
              end
            end
            if scenerio[:overlay_path]
              overlay_hierarchy = ReferenceParser.cfr_best_guess_hierarchy(overlay)
              overlay_path = ReferenceParser::Cfr.url(overlay_hierarchy, {on: "current", relative: true})
              expect(overlay_path).to eq(scenerio[:overlay_path])
            end
          end

          if scenerio[:overlay_link]
            overlay_link = ReferenceParser::Cfr.linked_overlay_for(scenerio[:hierarchy])
            if scenerio[:overlay_link] == :none
              expect(overlay_link).to be_nil
            else
              expect(overlay_link).to eq(scenerio[:overlay_link])
            end
          end
        end
      end
    end
  end

  it "returns known overlay chapters" do
    expect(ReferenceParser::Cfr).not_to be_known_overlay_chapter(title: "48", chapter: "1")
    expect(ReferenceParser::Cfr).to be_known_overlay_chapter(title: "48", chapter: "2")
    expect(ReferenceParser::Cfr).not_to be_known_overlay_chapter(title: "48", chapter: "4")
  end
end
