require "rails_helper"

RSpec.describe "Api::V1::Words", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:wordbook) { create(:wordbook, user: user) }

  describe "GET /api/v1/wordbooks/:wordbook_id/words" do
    it "returns current user's words" do
      create_list(:word, 3, wordbook: wordbook)
      create(:word) # another user's word

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it "includes first_meaning for each word" do
      word = create(:word, wordbook: wordbook)
      create(:meaning, word: word, content: "second", display_order: 2)
      create(:meaning, word: word, content: "first", display_order: 1)

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      returned_word = response.parsed_body.find { |w| w["id"] == word.id }
      expect(returned_word["first_meaning"]["content"]).to eq("first")
      expect(returned_word["first_meaning"]["display_order"]).to eq(1)
    end

    it "returns null first_meaning when word has no meanings" do
      create(:word, wordbook: wordbook)

      get "/api/v1/wordbooks/#{wordbook.id}/words", headers: headers

      expect(response.parsed_body.first["first_meaning"]).to be_nil
    end

    it "returns 401 without authentication" do
      get "/api/v1/wordbooks/#{wordbook.id}/words"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/wordbooks/:wordbook_id/words/:id" do
    it "returns the word" do
      word = create(:word, wordbook: wordbook, spelling: "apple")

      get "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["spelling"]).to eq("apple")
    end

    it "returns not_found for another user's word" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/wordbooks/:wordbook_id/words" do
    context "with valid params" do
      it "creates a word" do
        expect {
          post "/api/v1/wordbooks/#{wordbook.id}/words", params: { word: { spelling: "banana", status: "not_studied" } }, headers: headers
        }.to change(Word, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["spelling"]).to eq("banana")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        post "/api/v1/wordbooks/#{wordbook.id}/words", params: { word: { spelling: "", status: "not_studied" } }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include("Spelling can't be blank")
      end
    end

    it "returns not_found when wordbook belongs to another user" do
      other_wordbook = create(:wordbook)

      post "/api/v1/wordbooks/#{other_wordbook.id}/words", params: { word: { spelling: "test", status: "not_studied" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/wordbooks/:wordbook_id/words/:id" do
    let(:word) { create(:word, wordbook: wordbook) }

    it "updates the word" do
      patch "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", params: { word: { spelling: "cherry" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["spelling"]).to eq("cherry")
    end

    it "returns not_found for another user's word" do
      other_wordbook = create(:wordbook)
      other_word = create(:word, wordbook: other_wordbook)

      patch "/api/v1/wordbooks/#{other_wordbook.id}/words/#{other_word.id}", params: { word: { spelling: "hacked" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/wordbooks/:wordbook_id/words/:id" do
    it "deletes the word" do
      word = create(:word, wordbook: wordbook)

      expect {
        delete "/api/v1/wordbooks/#{wordbook.id}/words/#{word.id}", headers: headers
      }.to change(Word, :count).by(-1)

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
