module JwtAuthenticatable
  extend ActiveSupport::Concern

  private

  def encode_jwt(user_id, expires_at: 30.days.from_now)
    payload = {
      sub: user_id,
      exp: expires_at.to_i,
      iat: Time.current.to_i
    }
    JWT.encode(payload, jwt_secret_key, 'HS256')
  end

  def decode_jwt(token)
    decoded = JWT.decode(token, jwt_secret_key, true, algorithm: 'HS256')
    decoded.first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  def jwt_secret_key
    Rails.application.secret_key_base
  end
end
