class AddLengthCheckConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :wordbooks, 'char_length(title) <= 255', name: 'check_wordbooks_title_length'
    add_check_constraint :words, 'char_length(spelling) <= 255', name: 'check_words_spelling_length'
    add_check_constraint :meanings, 'char_length(definition) <= 1000', name: 'check_meanings_definition_length'
    add_check_constraint :examples, 'char_length(sentence) <= 1000', name: 'check_examples_sentence_length'
    add_check_constraint :examples, 'char_length(translation) <= 1000', name: 'check_examples_translation_length'
  end
end
