module ScenarioHelper
  def expect_link_with_text(html, href:, text:)
    link = find_link_in_html(html, href)
    expect(link).not_to be_nil, "expected link with href #{href.inspect} in:\n#{html}"

    expect(normalize_link_inner_html(link.inner_html)).to eq(normalize_link_inner_html(text))
  end

  def find_link_in_html(html, href)
    Nokogiri::HTML.fragment(html).css("a").find { |node| node["href"] == href }
  end

  def normalize_link_inner_html(inner_html)
    Nokogiri::HTML.fragment(inner_html.to_s).to_html.strip
  end

  def expect_matching_references(references, scenario)
    return unless scenario[:expected_references]

    exempt = scenario[:exempt_reference_keys] || []
    actual = references.map { |reference| reference.except(*exempt) }
    expected = scenario[:expected_references]

    expected.each_with_index do |expected_reference, index|
      expected_reference.each do |key, value|
        next unless value == :not_present

        expect(reference_has_link_information?(actual[index], key)).to(
          be(false),
          "expected #{key} to be absent for #{actual[index][:text].inspect}, got #{actual[index][key].inspect}"
        )
      end
    end

    normalized_expected = expected.map { |reference| reference.reject { |_, value| value == :not_present } }
    normalized_actual = actual.each_with_index.map do |reference, index|
      not_present_keys = expected[index]&.select { |_, value| value == :not_present }&.keys
      reference.except(*not_present_keys)
    end

    expect(normalized_actual).to eq(normalized_expected)
  end

  def reference_has_link_information?(reference, key)
    case key
    when :link
      link = reference[:link]
      link.present? && link.to_s.match?(/<a\s[^>]*href/i)
    else
      reference[key].present?
    end
  end
end
