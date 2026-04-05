class JsonWebToken
  DEFAULT_EXPIRATION = 30.days

  def self.encode(user_id, expires_at: DEFAULT_EXPIRATION.from_now)
    payload = {
      sub: user_id,
      exp: expires_at.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, secret_key, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: 'HS256')
    decoded.first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
  private_class_method :secret_key
end
