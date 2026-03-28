class AddCheckConstraintToUsersProvider < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :users,
                         "provider IN ('google', 'guest')",
                         name: 'check_users_provider_values'
  end
end
