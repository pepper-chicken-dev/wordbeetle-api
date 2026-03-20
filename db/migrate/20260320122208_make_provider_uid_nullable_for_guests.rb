class MakeProviderUidNullableForGuests < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :provider_uid, true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE users
            ADD CONSTRAINT chk_provider_uid_required_for_non_guest
            CHECK (provider = 'guest' OR provider_uid IS NOT NULL)
        SQL
      end

      dir.down do
        execute <<~SQL
          ALTER TABLE users
            DROP CONSTRAINT chk_provider_uid_required_for_non_guest
        SQL
      end
    end
  end
end
