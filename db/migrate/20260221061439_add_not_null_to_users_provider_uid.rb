class AddNotNullToUsersProviderUid < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :provider_uid, false
  end
end
