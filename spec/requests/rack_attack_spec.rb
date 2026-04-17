require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    Rack::Attack.cache.store = memory_store
  end

  after do
    Rack::Attack.reset!
    Rack::Attack.cache.store = Rails.cache
  end

  describe 'auth/guest throttle' do
    it 'blocks requests exceeding 5 per minute' do
      5.times { post '/api/v1/auth/guest' }
      expect(response).to have_http_status(:created)

      post '/api/v1/auth/guest'
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'auth/google throttle' do
    before do
      allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(
        'sub' => 'google_uid_123',
        'email' => 'test@example.com',
        'name' => 'Test User',
        'picture' => 'https://example.com/avatar.jpg'
      )
    end

    it 'blocks requests exceeding 5 per minute' do
      5.times { post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer google-token' } }
      expect(response).to have_http_status(:ok)

      post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer google-token' }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'health check safelist' do
    it 'is never throttled' do
      10.times { get '/up' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'throttled response format' do
    it 'returns JSON with error message and Retry-After header' do
      6.times { post '/api/v1/auth/guest' }

      expect(response.content_type).to include('application/json')
      expect(response.parsed_body['error']).to match(/Rate limit exceeded/)
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
