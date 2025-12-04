require "spec_helper"

CFR_PERFORMANCE_SCENARIOS = [
  "expanded preable local list of paragraphs", [
    {ex: '<span class="paragraph-hierarchy"><span class="paren">(</span>A<span class="paren">)</span></span> OEPA Ohio Administrative Code (OAC) Rule 3745-21-01, Definitions, Paragraphs (B)(1), (B)(2), (B)(6), (D)(6), (D)(8), (D)(22), (D)(45), (D)(48), (D)(58), (M)(8); effective January 17, 1995. </p></div>
      <div id="p-52.1894(c)(103)(i)(B)"><p class="indent-4" data-title="52.1894(c)(103)(i)(B)"><span class="paragraph-hierarchy"><span class="paren">(</span>B<span class="paren">)</span></span> OEPA OAC Rule 3745-21-04, Attainment Dates and Compliance Time Schedules, Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b) and (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c), and (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65); effective January 17, 1995. </p></div>
      <div id="p-52.1894(c)(103)(i)(C)"><p class="indent-4" data-title="52.1894(c)(103)(i)(C)">'},
    {ex: "Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b) and (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c), and (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65)"},
    {ex: "Paragraphs (B), (C)(3)(c), (C)(4)(b), (C)(5)(b), (C)(6)(b), (C)(8) (b), (c), (C)(9)(b), (C)(10)(b), (C)(19) (b), (c),  (d), (C)(28)(b), (C)(38), (C)(39), (C)(42), (C)(43), (C)(44), (C)(45), (C)(47), (C)(55), (C)(65)"},
    {ex: "<p>The Director of the Federal Register may make exceptions to the requirements of this subpart relating to placement and form of citations of authority whenever the Director determines that strict application would impair the practical use of the citations. </p>", options: {cfr: {context: {composite_hierarchy: "1::I:E:21:B:21.42"}}}},
    {ex: '<div class="section" id="21.42"><h8>§ 21.42 Exceptions.</h8><p>{:total_time=&gt;0.004282000008970499, :initial_cost=&gt;0, :best_interpretation_improvement_count=&gt;0, :level_system=&gt;"(a)(1)(i)(A)(_1_)(_i_)", :multiroot=&gt;false, :cost=&gt;0, :timed_out=&gt;false}</p><p>The Director of the Federal Register may make exceptions to the requirements of this subpart relating to placement and form of citations of authority whenever the Director determines that strict application would impair the practical use of the citations. </p><p class="citation">[37 FR 23611, Nov. 4, 1972, as amended at 54 FR 9682, Mar. 7, 1989] </p></div>', options: {cfr: {context: {composite_hierarchy: "1::I:E:21:B:21.42"}}}},
    {ex: "Chapter 20 is divided into parts, subparts, sections, subsections, paragraphs, and further subdivisions as necessary.", options: {cfr: {context: {composite_hierarchy: "48::20:A:2001:2001.1:2001.104-2", title: "48", chapter: "20", subchapter: "A", part: "2001", subpart: "2001.1", section_identifier: "2001.104-2", section: "2001.104-2"}}}}
  ]
]

RSpec.describe ReferenceParser::Cfr do
  describe "perf triggering fragments" do
    CFR_PERFORMANCE_SCENARIOS.each_slice(2) do |description, examples|
      describe description do
        let(:default_options) { {timeout: 3} }

        examples.each_with_index do |example, index|
          example[:index] = index
          it "(#{index}) #{example[:ex].truncate(24)}" do
            expect {
              ReferenceParser.new(options: default_options.merge(example[:options] || {})).hyperlink(example[:ex])
            }.not_to raise_error
          end
        end
      end
    end
  end

  describe "diagnose perf triggering file" do
    if File.exist?("spec/fixtures/files/performance/performance_issue.html")
      let(:html) { File.read("spec/fixtures/files/performance/performance_issue.html") }
      let(:options) { {cfr: {context: {composite_hierarchy: "1::1.1", title: "1", section: "1.1"}}} }

      it "verify timeout" do
        t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        unless times_out(html, 0, html.length, options, timeout: 5 * 60)
          t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          delta = t2 - t1
          expect(delta).to be < 60
          fail("successfully processed in #{delta.round(2)}s")
        end
      end
    end

    def times_out(html, range_start, range_end, options, timeout: 3)
      ReferenceParser.new(options: {timeout: timeout}.merge(options || {})).hyperlink(html[range_start..range_end])
      false
    rescue ReferenceParser::ParseTimeout
      true
    end
  end
end
