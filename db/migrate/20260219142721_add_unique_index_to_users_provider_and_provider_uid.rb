class AddUniqueIndexToUsersProviderAndProviderUid < ActiveRecord::Migration[8.1]
  def change
    add_index :users, %i[provider provider_uid], unique: true, name: 'index_users_on_provider_and_provider_uid'
  end
end
