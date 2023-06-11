require "spec_helper"

ALTERNATE_REFERENCE_SCENARIOS = {
  "generic" => [
    {citation: "48 CFR 1.105-2", alternate: "FAR 1.105-2", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "1", section: "1.105-2"}},
    {citation: "48 CFR 814.202-4", alternate: "VAAR 814.202-4", primary: "48 CFR 14.202-4", primary_link: '<a href="/current/title-48/section-14.202-4" class="cfr external">48 CFR 14.202-4</a>', hierarchy: {title: "48", chapter: "8", section: "814.202-4"}},
    {citation: "48 CFR 3006.302-1", alternate: "HSAR 3006.302-1", primary: "48 CFR 6.302-1", primary_link: '<a href="/current/title-48/section-6.302-1" class="cfr external">48 CFR 6.302-1</a>', hierarchy: {title: "48", chapter: "30", section: "3006.302-1"}}
  ],
  "avoid repeating alias portion" => [
    {citation: "48 CFR Chapter 2", alternate: "DFARS", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2"}},
    {citation: "48 CFR Chapter 2 Subchapter A", alternate: "DFARS Subchapter A", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", subchapter: "A"}},
    {citation: "48 CFR Part 201", alternate: "DFARS Part 201", primary: "48 CFR Part 1", primary_link: '<a href="/current/title-48/part-1" class="cfr external">48 CFR Part 1</a>', hierarchy: {title: "48", chapter: "2", subchapter: "A", part: "201"}},
    {citation: "48 CFR Part 201 Subpart 201.1", alternate: "DFARS Part 201 Subpart 201.1", primary: "48 CFR Subpart 1.1", primary_link: '<a href="/current/title-48/subpart-1.1" class="cfr external">48 CFR Subpart 1.1</a>', hierarchy: {title: "48", chapter: "2", subchapter: "A", part: "201", subpart: "201.1"}}
  ],
  "structure" => [
    {citation: "48 CFR Part 631", alternate: "DOSAR Part 631", primary: "48 CFR Part 31", overlay_path: "/current/title-48/part-31", primary_link: '<a href="/current/title-48/part-31" class="cfr external">48 CFR Part 31</a>', hierarchy: {title: "48", chapter: "6", part: "631"}},
    {citation: "48 CFR Part 631", alternate: "DOSAR Part 631", primary: "48 CFR Part 31", overlay_path: "/current/title-48/part-31", primary_link: '<a href="/current/title-48/part-31" class="cfr external">48 CFR Part 31</a>', hierarchy: {title: 48, chapter: "6", part: "631"}},
    {citation: "48 CFR Part 631 Subpart 631.1", alternate: "DOSAR Part 631 Subpart 631.1", primary: "48 CFR Subpart 31.1", overlay_path: "/current/title-48/subpart-31.1", primary_link: '<a href="/current/title-48/subpart-31.1" class="cfr external">48 CFR Subpart 31.1</a>', hierarchy: {title: "48", chapter: "6", part: "631", subpart: "631.1"}},
    {citation: "48 CFR 631.101", alternate: "DOSAR 631.101", primary: "48 CFR 31.101", overlay_path: "/current/title-48/section-31.101", primary_link: '<a href="/current/title-48/section-31.101" class="cfr external">48 CFR 31.101</a>', hierarchy: {title: "48", chapter: "6", section: "631.101"}},
    {citation: "48 CFR Part 600", alternate: "DOSAR Part 600", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "6", part: "600"}},
    {citation: "Appendix A to Chapter 2, Title 48", alternate: "Appendix A, DFARS", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", appendix: "Appendix A to Chapter 2"}}
  ],
  "Part 70 or above of each agency chapter supplements the FAR" => [
    {citation: "48 CFR Part 360", alternate: "HHSAR Part 360", primary: "48 CFR Part 60", primary_link: '<a href="/current/title-48/part-60" class="cfr external">48 CFR Part 60</a>', hierarchy: {title: "48", chapter: "3", part: "360"}},
    {citation: "48 CFR Part 370", alternate: "HHSAR Part 370", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "3", part: "370"}}
  ],
  "Part 0 isn't an overlay" => [
    {citation: "48 CFR Part 200", alternate: "DFARS Part 200", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", part: "200"}}
  ],
  "7000 and above also supplements" => [
    {citation: "48 CFR 323.7000", alternate: "HHSAR 323.7000", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "3", section: "323.7000"}},
    {citation: "48 CFR Part 225 Subpart 225.79", alternate: "DFARS Part 225 Subpart 225.79", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", part: "225", subpart: "225.79"}},
    {citation: "48 CFR 225.7900", alternate: "DFARS 225.7900", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "225.7900"}},
    {citation: "48 CFR 225.7901-1", alternate: "DFARS 225.7901-1", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "225.7901-1"}},
    {citation: "48 CFR Part 304 Subpart 304.72", alternate: "HHSAR Part 304 Subpart 304.72", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "3", part: "304", subpart: "304.72"}},
    {citation: "48 CFR Part 925 Subpart 925.70", alternate: "DEAR Part 925 Subpart 925.70", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "9", part: "925", subpart: "925.70"}},
    {citation: "48 CFR 925.7000", alternate: "DEAR 925.7000", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "9", part: "925", section: "925.7000"}},
    {citation: "48 CFR 816.506-70", alternate: "VAAR 816.506-70", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "8", section: "816.506-70"}},
    {citation: "48 CFR 816.570", alternate: "VAAR 816.570", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "8", section: "816.570"}}
  ],
  "doesn't error" => [
    {citation: "48 CFR 111T.T111", alternate: "DFARS 111T.T111", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "111T.T111"}},
    {citation: "48 CFR 111-T.111-T", alternate: "DFARS 111-T.111-T", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "111-T.111-T"}},

    {citation: "48 CFR 111.T111", alternate: "DFARS 111.T111", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "111.T111"}},
    {citation: "48 CFR 111.111-T", alternate: "DFARS 111.111-T", primary: :none, primary_link: :none, hierarchy: {title: "48", chapter: "2", section: "111.111-T"}}

  ]
}

RSpec.describe ReferenceParser::CfrAliases do
  ALTERNATE_REFERENCE_SCENARIOS.each do |description, scenarios|
    describe "CFR aliases & overlays (#{description})" do
      scenarios.each do |scenerio|
        it "recognizes #{scenerio[:citation]}" do
          expect(
            ReferenceParser::Hierarchy.citation(scenerio[:hierarchy])
          ).to eq(scenerio[:citation])

          if scenerio[:alternate]
            expect(
              ReferenceParser::Cfr.alternate_reference_for(scenerio[:hierarchy])
            ).to eq(scenerio[:alternate])
          end

          if scenerio[:primary] || scenerio[:primary_path]
            details = ReferenceParser::Cfr.primary_details_for(scenerio[:hierarchy], {on: "current", relative: true})

            overlay = details&.[](:title)
            overlay_path = details&.[](:path)
            if scenerio[:primary]
              if scenerio[:primary] == :none
                expect(overlay).to be_nil
              else
                expect(overlay).to eq(scenerio[:primary])
              end
            end
            if scenerio[:primary_path]
              expect(overlay_path).to eq(scenerio[:primary_path])
            end
          end

          if scenerio[:primary_link]
            overlay_link = ReferenceParser::Cfr.linked_primary_for(scenerio[:hierarchy])
            if scenerio[:primary_link] == :none
              expect(overlay_link).to be_nil
            else
              expect(overlay_link).to eq(scenerio[:primary_link])
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
