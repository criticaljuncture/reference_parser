module ExampleHelper
  def describe_example(example, index: nil)
    result = ""
    result << "(#{index}) " if index
    result << example[:ex].to_s.truncate(24).to_s
    result << " (#{example[:additional_description]})" if example[:additional_description]
    result
  end

  def expect_passing_cfr_scenerios(description, examples)
    describe description do
      permute_examples(examples).each_with_index do |example, index|
        example[:index] = index
        it describe_example(example, index: index) do
          expect_passing_cfr_scenerio(example)
        end
      end
    end
  end

  def permute_examples(examples)
    additional_examples = examples.filter_map do |example|
      example_wrapped_in_italics(example)
    end

    examples += additional_examples if additional_examples.present?
    examples
  end

  private

  def example_wrapped_in_italics(example)
    unless example[:with_surrounding_text] || example[:ex].include?("em>") || example[:context_specific]
      example.merge(
        with_surrounding_text: "<em>" + example[:ex] + "</em>",
        additional_description: "wrapped in italics"
      )
    end
  end
end
