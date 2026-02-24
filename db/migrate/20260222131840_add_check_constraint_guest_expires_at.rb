class AddCheckConstraintGuestExpiresAt < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :users,
      "provider != 'guest' OR guest_expires_at IS NOT NULL",
      name: "check_guest_expires_at_presence"
  end
end
