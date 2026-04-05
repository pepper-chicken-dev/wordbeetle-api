module AuthenticationHelper
  def auth_headers_for(user)
    token = JsonWebToken.encode(user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
