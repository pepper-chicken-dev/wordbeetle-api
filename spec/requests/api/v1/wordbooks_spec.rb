require 'rails_helper'

RSpec.describe 'Api::V1::Wordbooks', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe 'GET /api/v1/wordbooks' do
    let(:endpoint_path) { '/api/v1/wordbooks' }

    it_behaves_like 'paginated endpoint', :wordbook, -> { { user: user } }

    it "returns current user's wordbooks" do
      create_list(:wordbook, 3, user: user)
      create(:wordbook) # another user's wordbook

      get '/api/v1/wordbooks', headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(3)
    end

    it 'returns empty array when no wordbooks exist' do
      get '/api/v1/wordbooks', headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data']).to eq([])
    end

    it 'returns 401 without authentication' do
      get '/api/v1/wordbooks'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/wordbooks/:id' do
    it 'returns the wordbook' do
      wordbook = create(:wordbook, user: user)

      get "/api/v1/wordbooks/#{wordbook.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['title']).to eq(wordbook.title)
    end

    it 'returns not_found for nonexistent wordbook' do
      get '/api/v1/wordbooks/999999', headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/wordbooks' do
    context 'with valid params' do
      it 'creates a wordbook for the current user' do
        expect do
          post '/api/v1/wordbooks', params: { wordbook: { title: 'English Vocab' } }, headers: headers
        end.to change(Wordbook, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body['title']).to eq('English Vocab')
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable_content' do
        post '/api/v1/wordbooks', params: { wordbook: { title: '' } }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to eq('Unprocessable entity')
      end
    end
  end

  describe 'PATCH /api/v1/wordbooks/:id' do
    let(:wordbook) { create(:wordbook, user: user) }

    context 'with valid params' do
      it 'updates the wordbook' do
        patch "/api/v1/wordbooks/#{wordbook.id}", params: { wordbook: { title: 'Updated Title' } }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['title']).to eq('Updated Title')
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable_content' do
        patch "/api/v1/wordbooks/#{wordbook.id}", params: { wordbook: { title: '' } }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      patch "/api/v1/wordbooks/#{other_wordbook.id}", params: { wordbook: { title: 'Hacked' } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/wordbooks/:id' do
    it 'deletes the wordbook' do
      wordbook = create(:wordbook, user: user)

      expect do
        delete "/api/v1/wordbooks/#{wordbook.id}", headers: headers
      end.to change(Wordbook, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      delete "/api/v1/wordbooks/#{other_wordbook.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
