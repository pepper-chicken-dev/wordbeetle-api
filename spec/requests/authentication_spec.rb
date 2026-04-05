require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  describe 'protected endpoints' do
    let(:user) { create(:user) }
    let!(:wordbook) { create(:wordbook, user: user) }

    context 'without Authorization header' do
      it 'returns 401' do
        get '/api/v1/wordbooks'

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Unauthorized')
      end
    end

    context 'with invalid token' do
      it 'returns 401' do
        get '/api/v1/wordbooks', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Unauthorized')
      end
    end

    context 'with expired token' do
      it 'returns 401' do
        token = JsonWebToken.encode(user.id, expires_at: 1.day.ago)

        get '/api/v1/wordbooks', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with token for nonexistent user' do
      it 'returns 401' do
        token = JsonWebToken.encode(999_999)

        get '/api/v1/wordbooks', headers: { 'Authorization' => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with valid token' do
      it 'allows access' do
        get '/api/v1/wordbooks', headers: auth_headers_for(user)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
