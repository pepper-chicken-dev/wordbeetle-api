module AuthenticationHelper
  def auth_headers_for(user)
    token = JWT.encode(
      { sub: user.id, exp: 30.days.from_now.to_i, iat: Time.current.to_i },
      Rails.application.secret_key_base,
      "HS256"
    )
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
