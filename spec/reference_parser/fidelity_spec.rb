require "spec_helper"

FIDELITY_SHAPES = {
  "nested Pub. L. section lists w/ parenthesized U.S.C. equivalents" => [
    "49 U.S.C. 114; Pub. L. 110-53 (121 Stat. 266, Aug. 3, 2007) secs. 1501 (6 U.S.C. 1151), 1512 (6 U.S.C. 1162) and 1517 (6 U.S.C. 1167).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151), 1512 (6 U.S.C. 1162), and 1517 (6 U.S.C. 1167).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151) and 1512 (6 U.S.C. 1162).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151); 1512 (6 U.S.C. 1162); and 1517 (6 U.S.C. 1167).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151) or 1512 (6 U.S.C. 1162).",
    "Pub. L. 110-53 sec. 1501 (6 U.S.C. 1151).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151), 1512 (6 U.S.C. 1162) and 1517 (6 U.S.C. 1167), as amended.",
    "49 U.S.C. 114, 5103; Pub. L. 110-53 secs. 1408 (6 U.S.C. 1137), 1501 (6 U.S.C. 1151), 1512 (6 U.S.C. 1162) and 1534 (6 U.S.C. 1184).",
    "Pub. L. 108-90 (117 Stat. 1156, Oct. 1, 2003), sec. 520 (6 U.S.C. 469), as amended by Pub. L. 110-329 (122 Stat. 3689, Sept. 30, 2008) sec. 543 (6 U.S.C. 469).",
    "Pub. L. 107-71, sec. 101 (49 U.S.C. 114) and sec. 110 (49 U.S.C. 44901).",
    "Pub. L. 110-53 secs. 1501 (6 U.S.C. 1151a), 1512 (6 U.S.C. 1162(b)) and 1517 (6 U.S.C. 1167).",
    "Subparts A through E issued under 5 U.S.C. 6133(a) (read with 5 U.S.C. 6129) and 6326(b).",
    "49 U.S.C. Chapter 301 or Chapter 325.",
    "49 U.S.C. chapters 5, 51, 131-141, 145-149, 311, 313, and 315",
    "49 U.S.C. 113, 501 et seq., subchapters I and III of chapter 311, chapter 313, and 31502."
  ],
  "et seq. where the comma inside <em> is the only list divider" => [
    "12 U.S.C. 248(i)-(j), 343 <em>et seq.,</em> 347a, 347b, 347c, 348 <em>et seq.,</em> 357, 374, 374a, and 461.",
    "12 U.S.C. 343 <em>et seq.,</em> 347a.",
    "12 U.S.C. 343 <em>et seq.,</em> and 347a.",
    "12 U.S.C. 343 <em>et seq.,</em> 347a, and 461.",
    "12 U.S.C. 343 <em>et seq.</em>, 347a.",
    "15 U.S.C. 77c, 7202, and 7211 <em>et seq.,</em> unless otherwise noted. ",
    "12 U.S.C. 343 <em>et seq.,</em> unless otherwise noted."
  ],
  "Pub. L. attribution asides interrupting a list" => [
    "16 U.S.C. 1361 <em>et seq.,</em> as amended by Pub. L. 97-58.",
    "16 U.S.C. 1361 et seq., as amended by Pub. L. 97-58.",
    "16 U.S.C. 1361, as amended by Pub. L. 110-329.",
    "16 U.S.C. 1361, as amended by Pub. L. 110-329 and Pub. L. 111-11.",
    "16 U.S.C. 1361, as amended by Pub. L. 110-329, and Pub. L. 111-11.",
    "16 U.S.C. 1361, as amended by section 5 of Pub. L. 110-329.",
    "16 U.S.C. 1361, added by Pub. L. 110-53.",
    "16 U.S.C. 1361, as amended by Pub. L. 110-329, 122 Stat. 3689.",
    "16 U.S.C. 1361 et seq., as amended by Pub. L. 97-58, and 1362.",
    "16 U.S.C. 1361, as amended, and 1362.",
    "18 U.S.C. 842, 845; Pub. L. 108-90 (117 Stat. 1156, Oct. 1, 2003), sec. 520 (6 U.S.C. 469), as amended by Pub. L. 110-329 (122 Stat. 3689, Sept. 30, 2008) sec. 543 (6 U.S.C. 469).",
    "49 U.S.C. 113, 501 <em>et seq.</em>, subchapters I and III of chapter 311, chapter 313, and 31502; sec. 5204 of Pub. L. 114-94, 129 Stat. 1312, 1536."
  ],
  "sublocator lists relocated out of link text" => [
    "12 U.S.C. 248(i), (j), and 248-1, 342, 360, 464, 4001-4010, and 5001-5018.",
    "12 U.S.C. 248(i), (j).",
    "12 U.S.C. 248(i), (j), (k).",
    "12 U.S.C. 248(a), (b), and 342.",
    "12 U.S.C. 248(i) and (j).",
    "12 U.S.C. 248(i), (j) and 342.",
    "12 U.S.C. 248(i); (j); 342.",
    "12 U.S.C. 248(i), (j), 248-1.",
    "5 U.S.C. 552a(b)(1), (b)(2), and (b)(3).",
    "15 U.S.C. 78o(b), (c), and 78o-4.",
    "5 U.S.C. 552a(a) and (b)",
    "17 U.S.C. 203, 304(c) and (d)",
    "15 U.S.C. 78<em>o</em>(b)(11)(A), (c), and 78mm.",
    "5 U.S.C. 6133(a) (read with 5 U.S.C. 6129) and 6326(b)"
  ],
  "et seq. punctuation variants" => [
    "12 U.S.C. 1757, 1766(a), 1781-1790, 1790d, 3331 <em>et seq;</em> 31 U.S.C. 3717.",
    "12 U.S.C. 3331 <em>et seq;</em> 31 U.S.C. 3717.",
    "12 U.S.C. 3331 <em>et seq.;</em> 31 U.S.C. 3717.",
    "12 U.S.C. 3331 <em>et seq.,</em> 3717.",
    "12 U.S.C. 3331 <em>et seq.</em>; 31 U.S.C. 3717.",
    "12 U.S.C. 3331 <em>et seq;</em> and 3717.",
    "12 U.S.C. 1757, 3331 <em>et seq;</em> 3717, 3718.",
    "15 U.S.C. 7202, and 7211 <em>et seq.,</em> unless otherwise noted. ",
    "12 U.S.C. 248(i), (j), and 248-1, 342, 360, 464, 4001-4010, and 5001-5018.",
    "12 U.S.C. 248(i)-(j), 343 <em>et seq.,</em> 347a, 347b, 347c, 348 <em>et seq.,</em> 357, 374, 374a, and 461."
  ],
  "chapter folded into the section list" => [
    "5 U.S.C. chapter 43 and 5307(d).",
    "49 U.S.C. chapter 401 and 5307.",
    "5 U.S.C. subtitle I and chapters 401, 411.",
    "5 U.S.C. chapter 43 and 5307(d); 5 CFR part 430."
  ],
  "paragraph-only continuations merged into the preceding citation" => [
    "12 U.S.C. 5511, 5512, 5514(b), 5531(b), (c), and (d), 5532.",
    "12 U.S.C. 5531(b), (c), and (d), 5532.",
    "12 U.S.C. 5531(b), (c), and (d).",
    "12 U.S.C. 5531(b), and (c), 5532.",
    "12 U.S.C. 5531(b), (c), (d), and (e), 5532.",
    "12 U.S.C. 5531(b) and (c), 5532.",
    "12 U.S.C. 5531(b), (c) or (d), 5532.",
    "17 U.S.C. 203, 304(c) and (d)",
    "5 U.S.C. 552a(b)(1) through (11)",
    "12 U.S.C. 248(i), (j), and 248-1, 342.",
    "5 U.S.C. 5312, 5313, 5314, 5315 or 5316"
  ]
}

RSpec.describe "text fidelity" do # rubocop:disable RSpec/DescribeClass
  FIDELITY_SHAPES.each do |description, examples|
    describe description do
      examples.each do |example|
        it example.truncate(60) do
          result = reference_parser_for.hyperlink(example, default: {target: nil, class: nil})
          expect(Nokogiri::HTML.parse(result).text).to eq(Nokogiri::HTML.parse(example).text)
        end
      end
    end
  end
end
