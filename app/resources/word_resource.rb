class WordResource
  include Alba::Resource

  attributes :id, :spelling, :status, :next_review_at

  attribute :first_meaning, if: proc { |_word| params[:include_first_meaning] } do |word|
    word.first_meaning ? { definition: word.first_meaning.definition } : nil
  end

  attribute :meanings, if: proc { |_word| params[:includes]&.include?('meanings') } do |word|
    word.meanings.sort_by(&:display_order).map do |m|
      { id: m.id, definition: m.definition, display_order: m.display_order }
    end
  end

  attribute :examples, if: proc { |_word| params[:includes]&.include?('examples') } do |word|
    word.examples.sort_by(&:display_order).map do |e|
      { id: e.id, sentence: e.sentence, translation: e.translation, display_order: e.display_order }
    end
  end
end
