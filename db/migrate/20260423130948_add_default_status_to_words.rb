class AddDefaultStatusToWords < ActiveRecord::Migration[8.1]
  def change
    change_column_default :words, :status, from: nil, to: 'not_studied'
  end
end
