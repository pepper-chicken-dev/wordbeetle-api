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
      exception&.message || 'Bad request'
    when 401
      exception.is_a?(GoogleIdToken::VerificationError) ? 'Invalid ID token' : 'Unauthorized'
    when 404
      'Not found'
    when 409
      'Duplicate record'
    when 500
      log_server_error(exception) if exception
      'Internal server error'
    else
      Rack::Utils::HTTP_STATUS_CODES.fetch(status, 'Unknown error')
    end
  end

  def log_server_error(exception)
    Rails.logger.error("Unhandled error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace&.first(10)&.join("\n"))
  end
end
