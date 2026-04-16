class ErrorsController < ActionController::API
  def show
    status = params[:status].to_i
    render json: { error: error_message(status) }, status: status
  end

  private

  def error_message(status)
    exception = request.env['action_dispatch.exception']

    case status
    when 400
      log_client_error(status)
      exception&.message || 'Bad request'
    when 401
      log_client_error(status)
      exception.is_a?(GoogleIdToken::VerificationError) ? 'Invalid ID token' : 'Unauthorized'
    when 404
      log_client_error(status)
      'Not found'
    when 409
      log_client_error(status)
      'Duplicate record'
    when 500
      log_server_error(exception) if exception
      'Internal server error'
    else
      log_server_error(exception) if status >= 500 && exception
      Rack::Utils::HTTP_STATUS_CODES.fetch(status, 'Unknown error')
    end
  end

  def log_client_error(status)
    original_method = request.env['action_dispatch.original_request_method'] || request.method
    original_path = request.env['action_dispatch.original_path'] || request.path
    Rails.logger.warn("Client error: #{status} #{original_method} #{original_path}")
  end

  def log_server_error(exception)
    Rails.logger.error("Unhandled error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace&.first(10)&.join("\n"))
  end
end
