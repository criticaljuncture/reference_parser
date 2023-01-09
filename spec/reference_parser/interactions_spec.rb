require "spec_helper"

INTERACTION_SCENARIOS = [
  {description: "complex USC list + Pub. L.", ex: "15 U.S.C. 77b, 77b note, 77c, 77d, 77f, 77g, 77h, 77j, 77r, 77s, 77z-3, 77sss, 78c, 78d, 78j, 78<em>l,</em> 78m, 78n, 78o, 78o-7 note, 78t, 78w, 78<em>ll</em>(d), 78mm, 80a-8, 80a-24, 80a-28, 80a-29, 80a-30, and 80a-37, and Pub. L. 112-106, sec. 201(a), sec. 401, 126 Stat. 313 (2012), unless otherwise noted.",
   expected_html: '<a href="https://www.govinfo.gov/link/uscode/15/77b">15 U.S.C. 77b</a>, <a href="https://www.govinfo.gov/link/uscode/15/77b">77b note</a>, <a href="https://www.govinfo.gov/link/uscode/15/77c">77c</a>, <a href="https://www.govinfo.gov/link/uscode/15/77d">77d</a>, <a href="https://www.govinfo.gov/link/uscode/15/77f">77f</a>, <a href="https://www.govinfo.gov/link/uscode/15/77g">77g</a>, <a href="https://www.govinfo.gov/link/uscode/15/77h">77h</a>, <a href="https://www.govinfo.gov/link/uscode/15/77j">77j</a>, <a href="https://www.govinfo.gov/link/uscode/15/77r">77r</a>, <a href="https://www.govinfo.gov/link/uscode/15/77s">77s</a>, <a href="https://www.govinfo.gov/link/uscode/15/77z-3">77z-3</a>, <a href="https://www.govinfo.gov/link/uscode/15/77sss">77sss</a>, <a href="https://www.govinfo.gov/link/uscode/15/78c">78c</a>, <a href="https://www.govinfo.gov/link/uscode/15/78d">78d</a>, <a href="https://www.govinfo.gov/link/uscode/15/78j">78j</a>, <a href="https://www.govinfo.gov/link/uscode/15/78l">78<em>l,</em></a> <a href="https://www.govinfo.gov/link/uscode/15/78m">78m</a>, <a href="https://www.govinfo.gov/link/uscode/15/78n">78n</a>, <a href="https://www.govinfo.gov/link/uscode/15/78o">78o</a>, <a href="https://www.govinfo.gov/link/uscode/15/78o-7">78o-7 note</a>, <a href="https://www.govinfo.gov/link/uscode/15/78t">78t</a>, <a href="https://www.govinfo.gov/link/uscode/15/78w">78w</a>, <a href="https://www.govinfo.gov/link/uscode/15/78ll">78<em>ll</em>(d)</a>, <a href="https://www.govinfo.gov/link/uscode/15/78mm">78mm</a>, <a href="https://www.govinfo.gov/link/uscode/15/80a-8">80a-8</a>, <a href="https://www.govinfo.gov/link/uscode/15/80a-24">80a-24</a>, <a href="https://www.govinfo.gov/link/uscode/15/80a-28">80a-28</a>, <a href="https://www.govinfo.gov/link/uscode/15/80a-29">80a-29</a>, <a href="https://www.govinfo.gov/link/uscode/15/80a-30">80a-30</a>, and <a href="https://www.govinfo.gov/link/uscode/15/80a-37">80a-37</a>, and <a href="https://www.govinfo.gov/link/plaw/112/public/106">Pub. L. 112-106</a>, sec. 201(a), sec. 401, 126 Stat. 313 (2012), unless otherwise noted.'}
]

RSpec.describe "Interactions" do
  INTERACTION_SCENARIOS.each do |scenario|
    it scenario[:description] do
      result_html = ReferenceParser.new.hyperlink(scenario[:ex], default: {target: nil, class: nil})

      expect(result_html).to eq(scenario[:expected_html])
    end
  end
end
