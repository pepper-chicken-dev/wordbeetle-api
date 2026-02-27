require "rails_helper"

RSpec.describe "Api::V1::Words", type: :request do
  let(:user) { create(:user) }
  let(:wordbook) { create(:wordbook, user: user) }

  describe "GET /api/v1/words" do
    it "returns all words" do
      create_list(:word, 3, wordbook: wordbook)

      get "/api/v1/words"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end
  end

  describe "GET /api/v1/words/:id" do
    it "returns the word" do
      word = create(:word, wordbook: wordbook, spelling: "apple")

      get "/api/v1/words/#{word.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["spelling"]).to eq("apple")
    end
  end

  describe "POST /api/v1/words" do
    context "with valid params" do
      it "creates a word" do
        expect {
          post "/api/v1/words", params: { word: { wordbook_id: wordbook.id, spelling: "banana", status: "not_studied" } }
        }.to change(Word, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["spelling"]).to eq("banana")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        post "/api/v1/words", params: { word: { wordbook_id: wordbook.id, spelling: "", status: "not_studied" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include("Spelling can't be blank")
      end
    end
  end

  describe "PATCH /api/v1/words/:id" do
    let(:word) { create(:word, wordbook: wordbook) }

    it "updates the word" do
      patch "/api/v1/words/#{word.id}", params: { word: { spelling: "cherry" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["spelling"]).to eq("cherry")
    end
  end

  describe "DELETE /api/v1/words/:id" do
    it "deletes the word" do
      word = create(:word, wordbook: wordbook)

      expect {
        delete "/api/v1/words/#{word.id}"
      }.to change(Word, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
