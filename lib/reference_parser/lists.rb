module ReferenceParser::Lists
  private

  def split_list_parts(raw, divider:, keep: nil)
    return [[], []] if raw.blank?

    items = []
    dividers = []

    raw.split(/(#{divider})/).reject(&:empty?).each_with_index do |part, index|
      if index.even?
        item = part.strip
        items << item if item.present? && (!keep || keep.call(item))
      elsif items.size > dividers.size
        dividers << part
      end
    end

    [items, dividers]
  end

  # The label stays with the first item and dividers trail the preceding item.
  def build_list_citations(label, items, dividers)
    items.map.with_index do |item, index|
      yield(item).merge(
        text: index.zero? ? "#{label.to_s.strip} #{item}" : item,
        suffix: dividers[index] || ""
      )
    end
  end

  def map_labeled_list(raw, divider:, label:, keep: nil)
    items, dividers = split_list_parts(raw, divider: divider, keep: keep)
    return yield(items.first) unless items.many?

    build_list_citations(label, items, dividers) { |item| yield(item) }
  end
end
