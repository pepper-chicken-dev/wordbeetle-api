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
      log_client_error(status, exception)
      'Bad request'
    when 401
      log_client_error(status, exception)
      'Unauthorized'
    when 404
      log_client_error(status, exception)
      'Not found'
    when 409
      log_client_error(status, exception)
      'Duplicate record'
    when 422
      log_client_error(status, exception)
      'Unprocessable entity'
    when 500
      log_server_error(exception) if exception
      'Internal server error'
    else
      log_server_error(exception) if status >= 500 && exception
      Rack::Utils::HTTP_STATUS_CODES.fetch(status, 'Unknown error')
    end
  end

  def log_client_error(status, exception = nil)
    original_method = request.env['action_dispatch.original_request_method'] || request.method
    original_path = request.env['action_dispatch.original_path'] || request.path
    message = "Client error: #{status} #{original_method} #{original_path}"
    message += " - #{exception.class}: #{exception.message}" if exception
    Rails.logger.warn(message)
  end

  def log_server_error(exception)
    Rails.logger.error("Unhandled error: #{exception.class} - #{exception.message}")
    Rails.logger.error(exception.backtrace&.first(10)&.join("\n"))
  end
end
