class MoveExamplesFromWordsToMeanings < ActiveRecord::Migration[8.1]
  def up
    add_reference :examples, :meaning, null: true, foreign_key: true

    # Assign each example to the first meaning (by display_order) of its word
    execute <<~SQL
      UPDATE examples
      SET meaning_id = (
        SELECT meanings.id
        FROM meanings
        WHERE meanings.word_id = examples.word_id
        ORDER BY meanings.display_order ASC
        LIMIT 1
      )
    SQL

    # Create a default meaning for words that have examples but no meanings
    execute <<~SQL
      INSERT INTO meanings (word_id, definition, display_order, created_at, updated_at)
      SELECT DISTINCT e.word_id, '(定義なし)', 1, NOW(), NOW()
      FROM examples e
      WHERE e.meaning_id IS NULL
        AND NOT EXISTS (SELECT 1 FROM meanings m WHERE m.word_id = e.word_id)
    SQL

    # Re-assign any remaining orphaned examples
    execute <<~SQL
      UPDATE examples
      SET meaning_id = (
        SELECT meanings.id
        FROM meanings
        WHERE meanings.word_id = examples.word_id
        ORDER BY meanings.display_order ASC
        LIMIT 1
      )
      WHERE meaning_id IS NULL
    SQL

    change_column_null :examples, :meaning_id, false
    remove_reference :examples, :word, foreign_key: true
  end

  def down
    add_reference :examples, :word, null: true, foreign_key: true

    execute <<~SQL
      UPDATE examples
      SET word_id = (
        SELECT meanings.word_id
        FROM meanings
        WHERE meanings.id = examples.meaning_id
      )
    SQL

    change_column_null :examples, :word_id, false
    remove_reference :examples, :meaning, foreign_key: true
  end
end
