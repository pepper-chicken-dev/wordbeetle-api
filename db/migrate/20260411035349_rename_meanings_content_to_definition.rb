class RenameMeaningsContentToDefinition < ActiveRecord::Migration[8.1]
  def change
    rename_column :meanings, :content, :definition
  end
end
