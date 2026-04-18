require 'rails_helper'

RSpec.describe 'Api::V1::Meanings', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:wordbook) { create(:wordbook, user: user) }
  let(:word) { create(:word, wordbook: wordbook) }

  describe 'GET /api/v1/wordbooks/:wordbook_id/words/:word_id/meanings' do
    it "returns current user's meanings" do
      create_list(:meaning, 2, word: word)
      create(:meaning) # another user's meaning

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(2)
    end

    it 'returns 401 without authentication' do
      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/meanings", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    describe 'pagination' do
      it 'returns pagination metadata' do
        create_list(:meaning, 2, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings", headers: headers

        pagination = response.parsed_body['pagination']
        expect(pagination['current_page']).to eq(1)
        expect(pagination['total_count']).to eq(2)
        expect(pagination['per_page']).to eq(25)
        expect(pagination['total_pages']).to eq(1)
      end

      it 'supports per_page parameter' do
        create_list(:meaning, 3, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings", params: { per_page: 2 }, headers: headers

        expect(response.parsed_body['data'].size).to eq(2)
        expect(response.parsed_body['pagination']['total_pages']).to eq(2)
      end

      it 'supports page parameter' do
        create_list(:meaning, 3, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings",
            params: { per_page: 2, page: 2 }, headers: headers

        expect(response.parsed_body['data'].size).to eq(1)
        expect(response.parsed_body['pagination']['current_page']).to eq(2)
      end

      it 'clamps out-of-range page to last page' do
        create_list(:meaning, 2, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings",
            params: { page: 999 }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['pagination']['current_page']).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/wordbooks/:wordbook_id/words/:word_id/meanings/:id' do
    it 'returns the meaning' do
      meaning = create(:meaning, word: word, definition: '挨拶')

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings/#{meaning.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['definition']).to eq('挨拶')
    end

    it "returns not_found for another user's meaning" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_meaning = create(:meaning, word: other_word)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/meanings/#{other_meaning.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/wordbooks/:wordbook_id/words/:word_id/meanings' do
    context 'with valid params' do
      it 'creates a meaning' do
        expect do
          post "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings",
               params: { meaning: { definition: '意味', display_order: 1 } }, headers: headers
        end.to change(Meaning, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable_content' do
        post "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings",
             params: { meaning: { definition: '', display_order: 1 } }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'returns not_found when word belongs to another user' do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      post "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/meanings",
           params: { meaning: { definition: 'test', display_order: 1 } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/wordbooks/:wordbook_id/words/:word_id/meanings/:id' do
    let(:meaning) { create(:meaning, word: word) }

    it 'updates the meaning' do
      patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings/#{meaning.id}",
            params: { meaning: { definition: '更新された意味' } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['definition']).to eq('更新された意味')
    end

    it "returns not_found for another user's meaning" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_meaning = create(:meaning, word: other_word)

      patch "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/meanings/#{other_meaning.id}",
            params: { meaning: { definition: 'hacked' } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/wordbooks/:wordbook_id/words/:word_id/meanings/:id' do
    it 'deletes the meaning' do
      meaning = create(:meaning, word: word)

      expect do
        delete "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/meanings/#{meaning.id}", headers: headers
      end.to change(Meaning, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for another user's meaning" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_meaning = create(:meaning, word: other_word)

      delete "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/meanings/#{other_meaning.id}",
             headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
