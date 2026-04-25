class WordResource
  include Alba::Resource

  attributes :id, :spelling, :status, :next_review_at

  attribute :first_meaning, if: proc { |_word| params[:include_first_meaning] } do |word|
    word.first_meaning ? { definition: word.first_meaning.definition } : nil
  end

  attribute :meanings, if: proc { |_word|
    params[:includes]&.include?('meanings') || params[:includes]&.include?('examples')
  } do |word|
    include_examples = params[:includes]&.include?('examples')
    word.meanings.sort_by(&:display_order).map do |m|
      meaning_hash = { id: m.id, definition: m.definition, display_order: m.display_order }
      if include_examples
        meaning_hash[:examples] = m.examples.sort_by(&:display_order).map do |e|
          { id: e.id, sentence: e.sentence, translation: e.translation, display_order: e.display_order }
        end
      end
      meaning_hash
    end
  end
end
