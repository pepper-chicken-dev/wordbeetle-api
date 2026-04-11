class User < ApplicationRecord
  MigrationResult = Struct.new(:success, :user, :error, keyword_init: true) do
    def success?
      success
    end

    def self.success(user)
      new(success: true, user: user, error: nil)
    end

    def self.failure(error)
      new(success: false, user: nil, error: error)
    end
  end

  has_many :wordbooks, dependent: :destroy
  has_one :setting, dependent: :destroy

  validates :email, uniqueness: { allow_nil: true }
  validates :provider, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }, unless: -> { guest? }
  validates :guest_expires_at, presence: true, if: -> { provider == 'guest' }

  enum :provider, { google: 'google', guest: 'guest' }

  def self.find_by_token(token)
    payload = JsonWebToken.decode(token)
    return nil unless payload

    find_by(id: payload['sub'])
  end

  def migrate_to_google(google_payload)
    return MigrationResult.failure('User is not a guest') unless guest?

    ActiveRecord::Base.transaction do
      existing_google_user = User.find_by(provider: 'google', provider_uid: google_payload['sub'])

      if existing_google_user
        merge_into_google_user(existing_google_user)
      else
        convert_to_google(google_payload)
      end
    end
  end

  def effective_setting
    setting || Setting.default
  end

  private

  def convert_to_google(google_payload)
    update!(
      provider: 'google',
      provider_uid: google_payload['sub'],
      email: google_payload['email'],
      name: google_payload['name'],
      avatar_url: google_payload['picture'],
      guest_expires_at: nil
    )

    MigrationResult.success(self)
  end

  def merge_into_google_user(google_user)
    wordbooks.update_all(user_id: google_user.id) # rubocop:disable Rails/SkipsModelValidations
    setting.update!(user_id: google_user.id) if setting.present? && google_user.setting.blank?
    reload.destroy!

    MigrationResult.success(google_user)
  end
end
