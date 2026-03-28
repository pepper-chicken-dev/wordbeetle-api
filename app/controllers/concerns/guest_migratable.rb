module GuestMigratable
  extend ActiveSupport::Concern

  private

  def find_guest_user_from_token(token)
    payload = decode_jwt(token)
    return nil unless payload

    User.find_by(id: payload['sub'], provider: 'guest')
  end

  def migrate_guest_to_google(guest_user, google_payload)
    return { success: false, user: nil, error: 'User is not a guest' } unless guest_user.guest?

    ActiveRecord::Base.transaction do
      existing_google_user = User.find_by(provider: 'google', provider_uid: google_payload['sub'])

      if existing_google_user
        merge_guest_into_google_user(guest_user, existing_google_user)
      else
        convert_guest_to_google(guest_user, google_payload)
      end
    end
  end

  def convert_guest_to_google(guest_user, google_payload)
    guest_user.update!(
      provider: 'google',
      provider_uid: google_payload['sub'],
      email: google_payload['email'],
      name: google_payload['name'],
      avatar_url: google_payload['picture'],
      guest_expires_at: nil
    )

    { success: true, user: guest_user, error: nil }
  end

  def merge_guest_into_google_user(guest_user, google_user)
    guest_user.wordbooks.update_all(user_id: google_user.id) # rubocop:disable Rails/SkipsModelValidations

    guest_user.setting.update!(user_id: google_user.id) if guest_user.setting.present? && google_user.setting.blank?

    guest_user.reload.destroy!

    { success: true, user: google_user, error: nil }
  end
end
