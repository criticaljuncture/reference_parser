require "spec_helper"

FR_DOC_NUMBER_SCENARIOS = [
  {ex: "FR Doc. 2021-22057", citation: {doc_number: "2021-22057"}},
  {ex: "FR Document Number 2021-05296 (Pages 14313-14314)", citation: {doc_number: "2021-05296"}},
  {ex: "FR Document Number 2020-12413", citation: {doc_number: "2020-12413"}},
  {ex: "FR DOC# 2020-24608", citation: {doc_number: "2020-24608"}},
  {ex: "FR document: 2021-04052", citation: {doc_number: "2021-04052"}},
  {ex: "FR Document Number (FR Doc) 2020-22044", citation: {doc_number: "2020-22044"}},
  {ex: "FR document, 2020-07884,", citation: {doc_number: "2020-07884"}},
  {ex: "FR Document 2020-05700,", citation: {doc_number: "2020-05700"}},
  {ex: "FR Doc. 2021-22057 Filed ", citation: {doc_number: "2021-22057"}},
  {ex: "[FR Doc. C1-2022-21248 Filed 12-15-22; 8:45 am]", citation: {doc_number: "C1-2022-21248"}},
  {ex: "[FR Doc. C1-2022-12234 Filed 6-27-22; 8:45 am]", citation: {doc_number: "C1-2022-12234"}},
  {ex: "FR Doc. 2023-06310,", citation: {doc_number: "2023-06310"}},
  {ex: "FR Doc. 2023–06310,", citation: {doc_number: "2023-06310"}},
  {ex: "FR Doc. 2023—06310,", citation: {doc_number: "2023-06310"}}
]

RSpec.describe ReferenceParser::FederalRegisterDocNumber do
  describe "links Federal Register Document Numbers" do
    it "example usage" do
      expect(
        ReferenceParser.new(only: :federal_register_doc_number).hyperlink(
          "Lorem ipsum dolor sit amet, FR Doc. 2021-88888 consectetur adipiscing elit.",
          default: {target: nil, class: nil}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="https://www.federalregister.gov/d/2021-88888">FR Doc. 2021-88888</a> consectetur adipiscing elit.'
    end

    it "relative urls" do
      expect(
        ReferenceParser.new(only: :federal_register_doc_number).hyperlink(
          "Lorem ipsum dolor sit amet, FR Document Number 2021-99999 consectetur adipiscing elit.",
          default: {target: nil, class: nil, relative: true}
        )
      ).to eql 'Lorem ipsum dolor sit amet, <a href="/d/2021-99999">FR Document Number 2021-99999</a> consectetur adipiscing elit.'
    end

    FR_DOC_NUMBER_SCENARIOS.each do |scenario|
      [scenario[:ex]].flatten.each do |example|
        it example.to_s do
          result_html = ReferenceParser.new(only: :federal_register_doc_number).hyperlink(example, default: {target: nil, class: nil})

          citations = [scenario[:citation], scenario[:citations]].flatten.compact

          citations.each do |citation|
            expect(
              result_html
            ).to have_tag("a", with: {href: fr_doc_url(citation)})
          end

          expect(result_html).to have_tag("a", count: citations.count)

          [scenario[:expected_html]].flatten.compact.each do |expected_html|
            expect(result_html).to include(expected_html)
          end
        end
      end
    end

    def fr_doc_url(options)
      ReferenceParser::FederalRegisterDocNumber.new({}).url(options)
    end
  end

  describe "#linkable_document_number?" do
    let(:parser) { described_class.new({}) }

    it "returns true for non-standard document numbers" do
      expect(parser.linkable_document_number?("C1-2022-12345")).to be true
      expect(parser.linkable_document_number?("ABC-12345")).to be true
    end

    context "with 2-digit year format" do
      it "returns false for years between 30 and 93" do
        expect(parser.linkable_document_number?("73-13407")).to be false
        expect(parser.linkable_document_number?("30-12345")).to be false
        expect(parser.linkable_document_number?("93-31907")).to be false
      end

      it "returns true for years outside 30-93 range" do
        expect(parser.linkable_document_number?("29-12345")).to be true
        expect(parser.linkable_document_number?("94-12345")).to be true
        expect(parser.linkable_document_number?("05-12345")).to be true
      end
    end

    context "with 4-digit year format" do
      it "returns false for years before 1994" do
        expect(parser.linkable_document_number?("1993-12345")).to be false
        expect(parser.linkable_document_number?("1950-12345")).to be false
        expect(parser.linkable_document_number?("1800-12345")).to be false
      end

      it "returns true for years 1994 and later" do
        expect(parser.linkable_document_number?("1994-12345")).to be true
        expect(parser.linkable_document_number?("2000-12345")).to be true
        expect(parser.linkable_document_number?("2025-07333")).to be true
      end
    end

    context "with other formats" do
      it "returns true for non-standard document numbers" do
        expect(parser.linkable_document_number?("C1-2022-12345")).to be true
        expect(parser.linkable_document_number?("ABC-12345")).to be true
      end
    end
  end
end
