class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :hard_interval_days, null: false
      t.integer :uncertain_interval_days, null: false
      t.integer :easy_interval_days, null: false

      t.timestamps
    end
  end
end
