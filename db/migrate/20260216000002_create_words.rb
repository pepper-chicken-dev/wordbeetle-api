class CreateWords < ActiveRecord::Migration[8.1]
  def change
    create_table :words do |t|
      t.references :wordbook, null: false, foreign_key: true
      t.string :spelling, null: false
      t.string :status, null: false
      t.date :next_review_date

      t.timestamps
    end
  end
end
