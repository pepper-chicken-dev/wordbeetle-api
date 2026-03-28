module Authenticatable
  extend ActiveSupport::Concern

  include JwtAuthenticatable

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers['Authorization']&.split('Bearer ')&.last
    return render_unauthorized unless token

    payload = decode_jwt(token)
    return render_unauthorized unless payload

    @current_user = User.find_by(id: payload['sub'])
    render_unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
