require "spec_helper"

RSpec.describe ReferenceParser::UrlPrtpage do
  [
    {description: "errant space in domain", # /d/2023-17271/p-13
     source: "<em>https://seamap.env.duke .edu/models/Duke/EC/</em>",
     hints: ["https://seamap.env.duke.edu/models/Duke/EC/"],
     expected: '<em><a href="https://seamap.env.duke.edu/models/Duke/EC/" class="external" target="_blank" rel="noopener noreferrer">https://seamap.env.duke .edu/models/Duke/EC/</a></em>'},

    {description: "errant space in path (a)", # /d/2023-16708/p-7
     source: "<em>https://ferconline.ferc.gov/Quick Comment.aspx.</em>",
     hints: ["https://ferconline.ferc.gov/QuickComment.aspx"],
     expected: '<em><a href="https://ferconline.ferc.gov/QuickComment.aspx" class="external" target="_blank" rel="noopener noreferrer">https://ferconline.ferc.gov/&#8203;Quick Comment.aspx</a>.</em>'},

    {description: "archive + file", # /d/2023-15823/p-745
     source: "<em>https://www2.census.gov/programs-surveys/gov-finances/tables/2020/2020_Individual_Unit_File.zip, Fin_PID_2020.txt file</em>",
     hints: ["https://www2.census.gov/programs-surveys/gov-finances/tables/2020/2020_Individual_Unit_File.zip"],
     expected: '<em><a href="https://www2.census.gov/programs-surveys/gov-finances/tables/2020/2020_Individual_Unit_File.zip" class="external" target="_blank" rel="noopener noreferrer">https://www2.census.gov/&#8203;programs-surveys/&#8203;gov-finances/&#8203;tables/&#8203;2020/&#8203;2020_&#8203;Individual_&#8203;Unit_&#8203;File.zip</a>, Fin_&#8203;PID_&#8203;2020.txt file</em>'},

    {description: "multiple errant spaces in query params", # /d/2023-15073/p-241
     source: "<em>https://sab.epa.gov/ords/sab/f?p=114:0:16965043720403: APPLICATION_PROCESS=REPORT_DOC::: REPORT_ID:964.</em>",
     hints: ["https://sab.epa.gov/ords/sab/f?p=114:0:16965043720403:APPLICATION_PROCESS=REPORT_DOC:::REPORT_ID:964"],
     expected: '<em><a href="https://sab.epa.gov/ords/sab/f?p=114:0:16965043720403:APPLICATION_PROCESS=REPORT_DOC:::REPORT_ID:964" class="external" target="_blank" rel="noopener noreferrer">https://sab.epa.gov/&#8203;ords/&#8203;sab/&#8203;f?&#8203;p=&#8203;114:0:16965043720403: APPLICATION_PROCESS=REPORT_DOC::: REPORT_ID:964</a>.</em>'},

    {description: "errant space in path (b)", # /d/2023-15073/p-244
     source: "<em>https://doi.org/10.1016/j.buildenv. 2020.107359.</em>",
     hints: ["https://doi.org/10.1016/j.buildenv.2020.107359"],
     expected: '<em><a href="https://doi.org/10.1016/j.buildenv.2020.107359" class="external" target="_blank" rel="noopener noreferrer">https://doi.org/&#8203;10.1016/&#8203;j.buildenv. 2020.107359</a>.</em>'},

    {description: "errant space in path (c)", # /d/2023-15073/p-245
     source: "<em>https://doi.org/10.1016/j.scitotenv. 2019.07.295.</em>",
     hints: ["https://doi.org/10.1016/j.scitotenv.2019.07.295"],
     expected: '<em><a href="https://doi.org/10.1016/j.scitotenv.2019.07.295" class="external" target="_blank" rel="noopener noreferrer">https://doi.org/&#8203;10.1016/&#8203;j.scitotenv. 2019.07.295</a>.</em>'}
  ].each do |scenario|
    it "handles #{scenario[:description]}" do
      result = hyperlink("#{prefix}#{scenario[:source]}#{suffix}", hints: scenario[:hints]).delete_prefix(prefix).delete_suffix(suffix)

      expect(result).to eq(scenario[:expected])
    end
  end

  let(:prefix) { "Lorem ipsum dolor sit " }
  let(:suffix) { " amet, consectetuer adipiscing elit." }

  def hyperlink(text, hints: [])
    ReferenceParser.new(only: :url_prtpage, options: {html_awareness: :careful, hints: hints}).hyperlink(text)
  end
end
