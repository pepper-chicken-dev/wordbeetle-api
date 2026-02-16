class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :google_id
      t.string :name
      t.string :email
      t.string :avatar_url

      t.timestamps
    end
  end
end
