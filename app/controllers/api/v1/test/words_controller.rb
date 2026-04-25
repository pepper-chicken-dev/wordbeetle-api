module Api
  module V1
    module Test
      class WordsController < ApplicationController
        def index
          wordbook = current_user.wordbooks.find(params[:wordbook_id])
          words = wordbook.words.reviewable.includes(meanings: :examples)

          render json: {
            wordbook: WordbookResource.new(wordbook).serializable_hash,
            words: WordResource.new(words, params: { includes: %w[meanings examples] }).serializable_hash
          }
        end
      end
    end
  end
end
