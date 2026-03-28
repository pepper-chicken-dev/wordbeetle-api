class ApplicationController < ActionController::API
  include Authenticatable

  if Rails.env.production?
    rescue_from StandardError do |e|
      Rails.logger.error("Unhandled error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
      render json: { error: 'Internal server error' }, status: :internal_server_error
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: 'Not found' }, status: :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do
    render json: { error: 'Duplicate record' }, status: :conflict
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end
end
