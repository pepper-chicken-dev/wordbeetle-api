require 'rails_helper'

RSpec.describe 'Errors', type: :request do
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

  describe 'logging' do
    describe '4xx errors' do
      it 'logs a warning for 404 errors' do
        allow(Rails.logger).to receive(:warn)

        get '/nonexistent/path'

        expect(Rails.logger).to have_received(:warn).with('Client error: 404 GET /nonexistent/path')
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
