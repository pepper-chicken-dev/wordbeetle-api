require "rails_helper"

RSpec.describe "Api::V1::Wordbooks", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/wordbooks" do
    it "returns all wordbooks" do
      create_list(:wordbook, 3, user: user)

      get "/api/v1/wordbooks"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(3)
    end

    it "returns empty array when no wordbooks exist" do
      get "/api/v1/wordbooks"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/v1/wordbooks/:id" do
    it "returns the wordbook" do
      wordbook = create(:wordbook, user: user)

      get "/api/v1/wordbooks/#{wordbook.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["title"]).to eq(wordbook.title)
    end

    it "returns not_found for nonexistent wordbook" do
      get "/api/v1/wordbooks/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/wordbooks" do
    context "with valid params" do
      it "creates a wordbook" do
        expect {
          post "/api/v1/wordbooks", params: { wordbook: { user_id: user.id, title: "English Vocab" } }
        }.to change(Wordbook, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["title"]).to eq("English Vocab")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        post "/api/v1/wordbooks", params: { wordbook: { user_id: user.id, title: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]).to include("Title can't be blank")
      end
    end
  end

  describe "PATCH /api/v1/wordbooks/:id" do
    let(:wordbook) { create(:wordbook, user: user) }

    context "with valid params" do
      it "updates the wordbook" do
        patch "/api/v1/wordbooks/#{wordbook.id}", params: { wordbook: { title: "Updated Title" } }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["title"]).to eq("Updated Title")
      end
    end

    context "with invalid params" do
      it "returns unprocessable_entity" do
        patch "/api/v1/wordbooks/#{wordbook.id}", params: { wordbook: { title: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /api/v1/wordbooks/:id" do
    it "deletes the wordbook" do
      wordbook = create(:wordbook, user: user)

      expect {
        delete "/api/v1/wordbooks/#{wordbook.id}"
      }.to change(Wordbook, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
