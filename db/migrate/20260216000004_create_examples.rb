class CreateExamples < ActiveRecord::Migration[8.1]
  def change
    create_table :examples do |t|
      t.references :word, null: false, foreign_key: true
      t.text :sentence, null: false
      t.text :translation, null: false
      t.integer :display_order, null: false

      t.timestamps
    end
  end
end
