require "rails_helper"

RSpec.describe "Api::V1::Test::Words", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }
  let(:wordbook) { create(:wordbook, user: user) }

  describe "GET /api/v1/wordbooks/:wordbook_id/test/words" do
    it "returns reviewable words with meanings and examples" do
      word = create(:word, wordbook: wordbook, next_review_at: nil)
      meaning = create(:meaning, word: word, content: "りんご", display_order: 1)
      example = create(:example, word: word, sentence: "I like apples.", display_order: 1)

      get "/api/v1/wordbooks/#{wordbook.id}/test/words", headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["wordbook"]["id"]).to eq(wordbook.id)
      expect(body["wordbook"]["title"]).to eq(wordbook.title)
      expect(body["words"].size).to eq(1)

      returned_word = body["words"].first
      expect(returned_word["spelling"]).to eq(word.spelling)
      expect(returned_word["meanings"].size).to eq(1)
      expect(returned_word["meanings"].first["content"]).to eq("りんご")
      expect(returned_word["examples"].size).to eq(1)
      expect(returned_word["examples"].first["sentence"]).to eq("I like apples.")
    end

    it "includes words with next_review_at in the past" do
      word = create(:word, wordbook: wordbook, next_review_at: 1.day.ago)

      get "/api/v1/wordbooks/#{wordbook.id}/test/words", headers: headers

      expect(response.parsed_body["words"].size).to eq(1)
    end

    it "excludes words with next_review_at in the future" do
      create(:word, wordbook: wordbook, next_review_at: 1.day.from_now)

      get "/api/v1/wordbooks/#{wordbook.id}/test/words", headers: headers

      expect(response.parsed_body["words"].size).to eq(0)
    end

    it "returns meanings and examples sorted by display_order" do
      word = create(:word, wordbook: wordbook, next_review_at: nil)
      create(:meaning, word: word, content: "second", display_order: 2)
      create(:meaning, word: word, content: "first", display_order: 1)
      create(:example, word: word, sentence: "Second", display_order: 2)
      create(:example, word: word, sentence: "First", display_order: 1)

      get "/api/v1/wordbooks/#{wordbook.id}/test/words", headers: headers

      returned_word = response.parsed_body["words"].first
      expect(returned_word["meanings"].map { |m| m["content"] }).to eq(%w[first second])
      expect(returned_word["examples"].map { |e| e["sentence"] }).to eq(%w[First Second])
    end

    it "returns empty words array when no reviewable words exist" do
      create(:word, wordbook: wordbook, next_review_at: 1.day.from_now)

      get "/api/v1/wordbooks/#{wordbook.id}/test/words", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["words"]).to eq([])
    end

    it "returns 401 without authentication" do
      get "/api/v1/wordbooks/#{wordbook.id}/test/words"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns not_found for another user's wordbook" do
      other_wordbook = create(:wordbook)

      get "/api/v1/wordbooks/#{other_wordbook.id}/test/words", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
