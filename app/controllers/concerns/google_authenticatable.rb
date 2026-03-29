module GoogleAuthenticatable
  extend ActiveSupport::Concern

  private

  def verify_google_token(token)
    client_id = ENV.fetch('GOOGLE_CLIENT_ID', nil)

    begin
      Google::Auth::IDTokens.verify_oidc(token, aud: client_id)
    rescue Google::Auth::IDTokens::VerificationError => e
      Rails.logger.error("Google ID token verification failed: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error: #{e.message}")
      nil
    end
  end
end
