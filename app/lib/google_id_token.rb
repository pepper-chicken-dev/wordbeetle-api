class GoogleIdToken
  class VerificationError < StandardError; end

  def self.decode(token)
    Google::Auth::IDTokens.verify_oidc(token, aud: client_id)
  rescue Google::Auth::IDTokens::VerificationError => e
    Rails.logger.error("Google ID token verification failed: #{e.message}")
    raise VerificationError, e.message
  end

  def self.client_id
    ENV.fetch('GOOGLE_CLIENT_ID', nil)
  end
  private_class_method :client_id
end
