module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split('Bearer ')&.last
    raise AuthenticationError unless token

    @current_user = User.find_by_token(token)
    raise AuthenticationError unless @current_user
  end

  def current_user
    @current_user
  end
end
