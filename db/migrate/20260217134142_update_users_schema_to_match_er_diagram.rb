class UpdateUsersSchemaToMatchErDiagram < ActiveRecord::Migration[8.1]
  def change
    # google_id を provider_uid にリネーム
    rename_column :users, :google_id, :provider_uid

    # provider カラムを追加（必須）
    add_column :users, :provider, :string, null: false, default: "google"

    # guest_expires_at カラムを追加
    add_column :users, :guest_expires_at, :datetime

    # デフォルト値を削除（既存データに適用済み）
    change_column_default :users, :provider, from: "google", to: nil
  end
end
