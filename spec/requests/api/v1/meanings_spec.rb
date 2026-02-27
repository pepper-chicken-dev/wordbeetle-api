require "rails_helper"

RSpec.describe "Api::V1::Meanings", type: :request do
  let(:word) { create(:word) }

  describe "GET /api/v1/meanings" do
    it "returns all meanings" do
      create_list(:meaning, 2, word: word)

      get "/api/v1/meanings"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end
  end

  describe "GET /api/v1/meanings/:id" do
    it "returns the meaning" do
      meaning = create(:meaning, word: word, content: "挨拶")

      get "/api/v1/meanings/#{meaning.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("挨拶")
    end
  end

  describe "POST /api/v1/meanings" do
    context "with valid params" do
      it "creates a meaning" do
        expect {
          post "/api/v1/meanings", params: { meaning: { word_id: word.id, content: "意味", display_order: 1 } }
        }.to change(Meaning, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        post "/api/v1/meanings", params: { meaning: { word_id: word.id, content: "", display_order: 1 } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/meanings/:id" do
    let(:meaning) { create(:meaning, word: word) }

    it "updates the meaning" do
      patch "/api/v1/meanings/#{meaning.id}", params: { meaning: { content: "更新された意味" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["content"]).to eq("更新された意味")
    end
  end

  describe "DELETE /api/v1/meanings/:id" do
    it "deletes the meaning" do
      meaning = create(:meaning, word: word)

      expect {
        delete "/api/v1/meanings/#{meaning.id}"
      }.to change(Meaning, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
