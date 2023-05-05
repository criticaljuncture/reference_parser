module CfrHelper
  LOREM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

  def expect_passing_cfr_scenerio(example)
    embed_example_in_text = true
    embed_example_in_text = false if example.dig(:options, :cfr, :allow_aliases) && example.dig(:options, :cfr, :best_guess)
    text = ""
    text << LOREM[0..16] << " " if embed_example_in_text
    text << (example[:with_surrounding_text] || example[:ex])
    text << " " << LOREM[18..] << "." if embed_example_in_text
    text *= example[:repeat_reference] if example[:repeat_reference]

    expected_citation = [example[:citation], example[:citations]].flatten.compact.map do |target|
      target.respond_to?(:except) ? target.except(*example[:optional]) : target
    end
    expected_prior_urls = [example[:url_options]].flatten.compact

    result_html, references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: example[:context]}}))

    if expected_citation.present?
      if expected_citation == [:expect_none]
        expect(references.filter_map { |r| r[:hierarchy] }).to be_empty
      else
        expected_citation *= example[:repeat_reference] if example[:repeat_reference]

        # verify extracted references (if present)
        citations = references.filter_map { |r| r[:hierarchy] }
        references.each do |r|
          if r[:ambiguous].present?
            citations << {ambiguous: r[:ambiguous]}
          end
        end
        expect(citations).to eq(expected_citation.map { |c| c.except(:expected_url) })

        expected_citation.filter_map { |expected_citation| expected_citation[:expected_url] }.each do |expected_url|
          expect(result_html).to have_tag("a", with: {href: expected_url})
        end

      end
    elsif example[:expected_url].present?
      expect(result_html).to have_tag("a", with: {href: example[:expected_url]})
    end

    # verify expected_prior_urls (if present)
    expected_prior_urls.each do |expected_prior_url|
      href = prior_url_helper(:current, expected_prior_url)
      expect(result_html).to have_tag("a", with: {href: href})
    end

    (example[:expected_hrefs] || []).each do |href|
      expect(result_html).to have_tag("a", with: {href: href})
    end

    # confirm linking didn't damage source text
    references_only_result_html = references.map { |r| r[:result] }.join
    references_only_result_html_text = Nokogiri::HTML.parse(references_only_result_html).text
    result_html_text = Nokogiri::HTML.parse(result_html).text

    expect(result_html).to include(example[:expected_html]) if example[:expected_html].present?

    example_text = example[:text] || example[:ex]
    expect(references_only_result_html_text).to include(Nokogiri::HTML.parse(example_text).text) unless expected_prior_urls.present? || (expected_citation == [:expect_none]) || example[:expected_html].present? || example_text.is_a?(Array)
    expect(result_html_text).to include(Nokogiri::HTML.parse(example[:ex]).text) unless example[:html_appearance] == :expect_none || example[:ex].is_a?(Array)
    expect(result_html_text).to include(Nokogiri::HTML.parse(example[:with_surrounding_text]).text) if example[:with_surrounding_text].present?

    if expected_citation == [:expect_none]
      expect(
        references_only_result_html
      ).not_to have_tag("a")
    end

    # confirm specific url
    if references.count < 2 && (expected_citation != [:expect_none])
      if example[:text]&.include?("<") # have_tag vs <em>?
        expect(references_only_result_html).to include(example[:text] || example[:ex])
      else
        expect(
          references_only_result_html
        ).to have_tag("a", text: example[:text] || example[:ex],
          with: {href: example[:expected_url]}.tap { |h| h.delete(:href) unless h[:href].present? })
      end
    end

    if example[:context_specific]
      # confirm same results w/ composite hierarchy
      composite_hierarchy = "#{example.dig(:context, :title)}:#{example.dig(:context, :subtitle)}:#{example.dig(:context, :chapter)}:#{example.dig(:context, :subchapter)}:#{example.dig(:context, :part)}:#{example.dig(:context, :subpart)}:#{example.dig(:context, :section)}"
      composite_result_html, composite_references = extract_references(text, options: (example[:options] || {}).reverse_merge({cfr: {context: {composite_hierarchy: composite_hierarchy}}}))
      expect(composite_result_html).to eq(result_html)
      expect(composite_references).to eq(references)
    end
  end

  def part_or_section_string(hierarchy)
    return "" unless hierarchy[:part]
    return "/part-#{hierarchy[:part]}" unless hierarchy[:section]
    "/section-#{hierarchy[:part]}.#{hierarchy[:section]}"
  end

  def sublocators_string(hierarchy)
    return "" unless hierarchy[:sublocators]
    "#p-#{hierarchy[:part]}.#{hierarchy[:section]}#{hierarchy[:sublocators]}"
  end

  def prior_url_helper(date, hierarchy)
    path = "/current" if date == :current
    path ||= "/on/#{date.is_a?(String) ? date : date.to_formatted_s(:iso)}"
    path += "/title-#{hierarchy[:title]}"
    path += part_or_section_string(hierarchy)
    path += sublocators_string(hierarchy)
    path
  end

  def extract_references(text, options: {})
    citations = []
    result_html = ReferenceParser.new(options: options).each(text, default: {relative: true}) do |citation|
      citations << citation
    end
    [result_html, citations]
  end
end
