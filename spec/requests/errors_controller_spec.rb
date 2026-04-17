require 'rails_helper'

RSpec.describe 'ErrorsController', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe 'exception handling via exceptions_app' do
    it 'returns bad_request for ActionController::ParameterMissing' do
      post '/api/v1/wordbooks', params: {}, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to be_present
    end

    it 'returns unauthorized for GoogleIdToken::VerificationError' do
      allow(GoogleIdToken).to receive(:decode).and_raise(GoogleIdToken::VerificationError)

      post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('Unauthorized')
    end

    it 'returns not_found for ActiveRecord::RecordNotFound' do
      get '/api/v1/wordbooks/0', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Not found')
    end

    it 'returns conflict for ActiveRecord::RecordNotUnique' do
      allow(Wordbook).to receive(:new).and_raise(ActiveRecord::RecordNotUnique.new('Duplicate entry'))

      post '/api/v1/wordbooks', params: { wordbook: { title: 'Test' } }, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body['error']).to eq('Duplicate record')
    end
  end

  describe 'unknown routes' do
    it 'returns not_found for nonexistent GET path' do
      get '/nonexistent/path'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Not found')
      expect(response.content_type).to include('application/json')
    end

    it 'returns not_found for nonexistent POST path' do
      post '/nonexistent/path'

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body['error']).to eq('Not found')
    end
  end

  describe '5xx error responses' do
    it 'returns internal_server_error for unhandled exception' do
      exception = RuntimeError.new('something went wrong')

      get '/500', env: { 'action_dispatch.exception' => exception }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body['error']).to eq('Internal server error')
    end
  end

  describe 'logging' do
    describe '4xx errors' do
      it 'logs a warning with exception details for 404 errors' do
        allow(Rails.logger).to receive(:warn)

        get '/nonexistent/path'

        expect(Rails.logger).to have_received(:warn).with(
          a_string_starting_with('Client error: 404 GET /nonexistent/path - ')
        )
      end

      it 'logs a warning with exception details for 422 errors' do
        exception = ActiveRecord::RecordInvalid.new
        allow(Rails.logger).to receive(:warn)

        get '/422', env: { 'action_dispatch.exception' => exception }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Unprocessable entity')
        expect(Rails.logger).to have_received(:warn).with(
          a_string_matching(%r{Client error: 422 GET /422 - ActiveRecord::RecordInvalid:})
        )
      end
    end

    describe '5xx errors' do
      let(:exception) { StandardError.new('something went wrong') }

      before do
        exception.set_backtrace(Array.new(15) { |i| "app/models/foo.rb:#{i + 1}" })
      end

      it 'logs error with backtrace for 500 errors' do
        allow(Rails.logger).to receive(:error)

        get '/500', env: { 'action_dispatch.exception' => exception }

        expect(Rails.logger).to have_received(:error).with('Unhandled error: StandardError - something went wrong')
        expect(Rails.logger).to have_received(:error).with(exception.backtrace.first(10).join("\n"))
      end

      it 'logs error with backtrace for non-500 5xx errors' do
        allow(Rails.logger).to receive(:error)

        get '/502', env: { 'action_dispatch.exception' => exception }

        expect(Rails.logger).to have_received(:error).with('Unhandled error: StandardError - something went wrong')
        expect(Rails.logger).to have_received(:error).with(exception.backtrace.first(10).join("\n"))
      end
    end
  end
end
