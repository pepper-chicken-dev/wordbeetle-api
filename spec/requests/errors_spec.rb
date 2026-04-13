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
end
