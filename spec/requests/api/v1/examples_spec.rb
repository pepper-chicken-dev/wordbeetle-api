require 'rails_helper'

RSpec.describe 'Api::V1::Examples', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:wordbook) { create(:wordbook, user: user) }
  let(:word) { create(:word, wordbook: wordbook) }

  describe 'GET /api/v1/wordbooks/:wordbook_id/words/:word_id/examples' do
    it "returns current user's examples" do
      create_list(:example, 2, word: word)
      create(:example) # another user's example

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(2)
    end

    it 'returns 401 without authentication' do
      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/examples", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    describe 'pagination' do
      it 'returns pagination metadata' do
        create_list(:example, 2, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples", headers: headers

        pagination = response.parsed_body['pagination']
        expect(pagination['current_page']).to eq(1)
        expect(pagination['total_count']).to eq(2)
        expect(pagination['per_page']).to eq(25)
        expect(pagination['total_pages']).to eq(1)
      end

      it 'supports per_page parameter' do
        create_list(:example, 3, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples", params: { per_page: 2 }, headers: headers

        expect(response.parsed_body['data'].size).to eq(2)
        expect(response.parsed_body['pagination']['total_pages']).to eq(2)
      end

      it 'supports page parameter' do
        create_list(:example, 3, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples",
            params: { per_page: 2, page: 2 }, headers: headers

        expect(response.parsed_body['data'].size).to eq(1)
        expect(response.parsed_body['pagination']['current_page']).to eq(2)
      end

      it 'clamps out-of-range page to last page' do
        create_list(:example, 2, word: word)

        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples",
            params: { page: 999 }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['pagination']['current_page']).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/wordbooks/:wordbook_id/words/:word_id/examples/:id' do
    it 'returns the example' do
      example = create(:example, word: word, sentence: 'Good morning')

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples/#{example.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['sentence']).to eq('Good morning')
    end

    it "returns not_found for another user's example" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_example = create(:example, word: other_word)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/examples/#{other_example.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/wordbooks/:wordbook_id/words/:word_id/examples' do
    context 'with valid params' do
      it 'creates an example' do
        params = {
          example: {
            sentence: 'See you later',
            translation: 'またね',
            display_order: 1
          }
        }

        expect do
          post "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples", params: params, headers: headers
        end.to change(Example, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable_content' do
        post "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples",
             params: { example: { sentence: '', translation: '翻訳', display_order: 1 } }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'returns not_found when word belongs to another user' do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      post "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/examples",
           params: { example: { sentence: 'test', translation: 'test', display_order: 1 } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/wordbooks/:wordbook_id/words/:word_id/examples/:id' do
    let(:example_record) { create(:example, word: word) }

    it 'updates the example' do
      patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples/#{example_record.id}",
            params: { example: { sentence: 'Updated sentence' } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['sentence']).to eq('Updated sentence')
    end

    it "returns not_found for another user's example" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_example = create(:example, word: other_word)

      patch "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/examples/#{other_example.id}",
            params: { example: { sentence: 'hacked' } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/wordbooks/:wordbook_id/words/:word_id/examples/:id' do
    it 'deletes the example' do
      example_record = create(:example, word: word)

      expect do
        delete "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}/examples/#{example_record.id}", headers: headers
      end.to change(Example, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for another user's example" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)
      other_example = create(:example, word: other_word)

      delete "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}/examples/#{other_example.id}",
             headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
