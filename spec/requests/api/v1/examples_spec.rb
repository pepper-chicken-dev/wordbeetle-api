require "rails_helper"

RSpec.describe "Api::V1::Examples", type: :request do
  let(:word) { create(:word) }

  describe "GET /api/v1/examples" do
    it "returns all examples" do
      create_list(:example, 2, word: word)

      get "/api/v1/examples"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end
  end

  describe "GET /api/v1/examples/:id" do
    it "returns the example" do
      example = create(:example, word: word, sentence: "Good morning")

      get "/api/v1/examples/#{example.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["sentence"]).to eq("Good morning")
    end
  end

  describe "POST /api/v1/examples" do
    context "with valid params" do
      it "creates an example" do
        params = {
          example: {
            word_id: word.id,
            sentence: "See you later",
            translation: "またね",
            display_order: 1
          }
        }

        expect {
          post "/api/v1/examples", params: params
        }.to change(Example, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        post "/api/v1/examples", params: { example: { word_id: word.id, sentence: "", translation: "翻訳", display_order: 1 } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/examples/:id" do
    let(:example_record) { create(:example, word: word) }

    it "updates the example" do
      patch "/api/v1/examples/#{example_record.id}", params: { example: { sentence: "Updated sentence" } }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["sentence"]).to eq("Updated sentence")
    end
  end

  describe "DELETE /api/v1/examples/:id" do
    it "deletes the example" do
      example_record = create(:example, word: word)

      expect {
        delete "/api/v1/examples/#{example_record.id}"
      }.to change(Example, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
