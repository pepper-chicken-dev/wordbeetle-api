module GuestAuthenticatable
  extend ActiveSupport::Concern

  private

  def generate_guest_token(provider_uid)
    guest_verifier.generate(provider_uid, purpose: :guest_auth)
  end

  def verify_guest_token(token)
    guest_verifier.verify(token, purpose: :guest_auth)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def guest_verifier
    @guest_verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.key_generator.generate_key("guest_auth")
    )
  end
end
