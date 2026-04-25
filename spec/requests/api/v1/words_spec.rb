require 'rails_helper'

RSpec.describe 'Api::V1::Words', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:wordbook) { create(:wordbook, user: user) }

  describe 'GET /api/v1/wordbooks/:wordbook_id/words' do
    let(:endpoint_path) { "/api/v1/wordbooks/#{wordbook.id}/words" }

    it_behaves_like 'paginated endpoint', :word, -> { { wordbook: wordbook } }

    it "returns current user's words" do
      create_list(:word, 3, wordbook: wordbook)
      create(:word) # another user's word

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(3)
    end

    it 'includes first_meaning for each word' do
      word = create(:word, wordbook: wordbook)
      create(:meaning, word: word, definition: 'second', display_order: 2)
      create(:meaning, word: word, definition: 'first', display_order: 1)

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      returned_word = response.parsed_body['data'].find { |w| w['id'] == word.id }
      expect(returned_word['first_meaning']['definition']).to eq('first')
    end

    it 'returns null first_meaning when word has no meanings' do
      create(:word, wordbook: wordbook)

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      expect(response.parsed_body['data'].first['first_meaning']).to be_nil
    end

    it 'returns 401 without authentication' do
      get "/api/v1/wordbooks/#{wordbook.id}/words"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/wordbooks/:wordbook_id/words/:id' do
    it 'returns the word' do
      word = create(:word, wordbook: wordbook, spelling: 'apple')

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['spelling']).to eq('apple')
    end

    it "returns not_found for another user's word" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    context 'with include parameter' do
      let(:word) { create(:word, wordbook: wordbook) }
      let(:secondary_meaning) { create(:meaning, word: word, definition: 'meaning1', display_order: 2) }
      let(:primary_meaning) { create(:meaning, word: word, definition: 'meaning2', display_order: 1) }

      before do
        create(:example, meaning: secondary_meaning, sentence: 'Example1', display_order: 2)
        create(:example, meaning: primary_meaning, sentence: 'Example2', display_order: 1)
      end

      it 'includes meanings when include=meanings' do
        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}?include=meanings",
            headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['meanings'].size).to eq(2)
        expect(body['meanings'].pluck('definition')).to eq(%w[meaning2 meaning1])
        expect(body['meanings'].first).not_to have_key('examples')
      end

      it 'includes examples nested in meanings when include=examples' do
        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}?include=examples",
            headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['meanings'].size).to eq(2)
        expect(body['meanings'].first['examples'].size).to eq(1)
      end

      it 'includes meanings with examples when include=meanings,examples' do
        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}?include=meanings,examples",
            headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body['meanings'].size).to eq(2)
        expect(body['meanings'].first['examples'].size).to eq(1)
      end

      it 'ignores invalid include values' do
        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}?include=wordbook,invalid",
            headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).not_to have_key('wordbook')
        expect(body).not_to have_key('invalid')
      end

      it 'returns standard response without include parameter' do
        get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", headers: headers

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body).not_to have_key('meanings')
      end
    end
  end

  describe 'POST /api/v1/wordbooks/:wordbook_id/words' do
    context 'with valid params' do
      it 'creates a word and returns meanings in response' do
        expect do
          post "/api/v1/wordbooks/#{wordbook.id}/words",
               params: { word: { spelling: 'banana' } }, headers: headers
        end.to change(Word, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['spelling']).to eq('banana')
        expect(body['status']).to eq('not_studied')
        expect(body['meanings']).to eq([])
      end
    end

    context 'with meanings_attributes' do
      let(:params) do
        {
          word: {
            spelling: 'apple',
            meanings_attributes: [
              { definition: 'りんご', display_order: 1 },
              { definition: 'アップル社', display_order: 2 }
            ]
          }
        }
      end

      it 'creates a word with meanings in a single request' do
        expect do
          post "/api/v1/wordbooks/#{wordbook.id}/words", params: params, headers: headers
        end.to change(Word, :count).by(1).and change(Meaning, :count).by(2)

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['meanings'].size).to eq(2)
        expect(body['meanings'].pluck('definition')).to eq(%w[りんご アップル社])
      end
    end

    context 'with meanings_attributes containing examples_attributes' do
      let(:params) do
        {
          word: {
            spelling: 'run',
            meanings_attributes: [
              {
                definition: '走る', display_order: 1,
                examples_attributes: [
                  { sentence: 'I run every morning.', translation: '毎朝走ります。', display_order: 1 }
                ]
              }
            ]
          }
        }
      end

      it 'creates a word with meanings and examples atomically' do
        expect do
          post "/api/v1/wordbooks/#{wordbook.id}/words", params: params, headers: headers
        end.to change(Word, :count).by(1)
                                   .and change(Meaning, :count).by(1)
                                                               .and change(Example, :count).by(1)

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body['meanings'].size).to eq(1)
        expect(body['meanings'].first['examples'].size).to eq(1)
        expect(body['meanings'].first['examples'].first['sentence']).to eq('I run every morning.')
      end
    end

    context 'with invalid nested attributes' do
      it 'does not create any records when meaning validation fails' do
        params = {
          word: {
            spelling: 'apple',
            meanings_attributes: [{ definition: '', display_order: 1 }]
          }
        }

        word_count = Word.count
        meaning_count = Meaning.count
        post "/api/v1/wordbooks/#{wordbook.id}/words", params: params, headers: headers

        expect(Word.count).to eq(word_count)
        expect(Meaning.count).to eq(meaning_count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'does not create any records when example validation fails' do
        params = {
          word: {
            spelling: 'apple',
            meanings_attributes: [
              { definition: 'りんご', display_order: 1,
                examples_attributes: [{ sentence: '', translation: 'trans', display_order: 1 }] }
            ]
          }
        }

        word_count = Word.count
        example_count = Example.count
        post "/api/v1/wordbooks/#{wordbook.id}/words", params: params, headers: headers

        expect(Word.count).to eq(word_count)
        expect(Example.count).to eq(example_count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'ignores status parameter and always sets not_studied' do
      post "/api/v1/wordbooks/#{wordbook.id}/words",
           params: { word: { spelling: 'banana', status: 'easy' } }, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['status']).to eq('not_studied')
    end

    context 'with invalid params' do
      it 'returns unprocessable_content' do
        post "/api/v1/wordbooks/#{wordbook.id}/words", params: { word: { spelling: '' } },
                                                       headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to eq('Unprocessable entity')
      end
    end

    it 'returns not_found when wordbook belongs to another user' do
      other_wordbook = create(:wordbook)

      post "/api/v1/wordbooks/#{other_wordbook.id}/words",
           params: { word: { spelling: 'test' } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/wordbooks/:wordbook_id/words/:id' do
    let(:word) { create(:word, wordbook: wordbook) }

    it 'updates the word' do
      patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", params: { word: { spelling: 'cherry' } },
                                                                 headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['spelling']).to eq('cherry')
    end

    it "returns not_found for another user's word" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      patch "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}", params: { word: { spelling: 'hacked' } },
                                                                             headers: headers

      expect(response).to have_http_status(:not_found)
    end

    context 'when status changes' do
      it 'recalculates next_review_at and returns the updated value' do
        word = create(:word, wordbook: wordbook, status: 'easy', next_review_at: 10.days.from_now)

        freeze_time do
          patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}",
                params: { word: { status: 'hard' } }, headers: headers

          expect(response).to have_http_status(:ok)
          # easy(7d) → hard(1d): 6 days earlier
          expected = 10.days.from_now - 6.days
          expect(Time.zone.parse(response.parsed_body['next_review_at'])).to eq(expected)
        end
      end

      it 'sets next_review_at to nil when changing to not_studied' do
        word = create(:word, wordbook: wordbook, status: 'easy', next_review_at: 5.days.from_now)

        patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}",
              params: { word: { status: 'not_studied' } }, headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['next_review_at']).to be_nil
      end

      it 'sets next_review_at to now + interval when changing from not_studied' do
        word = create(:word, wordbook: wordbook, status: 'not_studied', next_review_at: nil)

        freeze_time do
          patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}",
                params: { word: { status: 'easy' } }, headers: headers

          expect(response).to have_http_status(:ok)
          expect(Time.zone.parse(response.parsed_body['next_review_at'])).to eq(7.days.from_now)
        end
      end
    end
  end

  describe 'DELETE /api/v1/wordbooks/:wordbook_id/words/:id' do
    it 'deletes the word' do
      word = create(:word, wordbook: wordbook)

      expect do
        delete "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", headers: headers
      end.to change(Word, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for another user's word" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      delete "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
