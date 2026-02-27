class AddCheckConstraintToWordsStatus < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE words SET status = 'not_studied' WHERE status NOT IN ('not_studied', 'hard', 'uncertain', 'easy')
    SQL

    add_check_constraint :words,
      "status IN ('not_studied', 'hard', 'uncertain', 'easy')",
      name: "check_words_status_values"
  end

  def down
    remove_check_constraint :words, name: "check_words_status_values"
  end
end
