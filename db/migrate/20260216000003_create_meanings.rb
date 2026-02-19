class CreateMeanings < ActiveRecord::Migration[8.1]
  def change
    create_table :meanings do |t|
      t.references :word, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :display_order, null: false

      t.timestamps
    end
  end
end
