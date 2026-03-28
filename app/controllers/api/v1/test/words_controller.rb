module Api
  module V1
    module Test
      class WordsController < ApplicationController
        def index
          wordbook = current_user.wordbooks.find(params[:wordbook_id])
          words = wordbook.words.reviewable.includes(:meanings, :examples)

          render json: {
            wordbook: wordbook.as_json(only: %i[id title]),
            words: words.map do |word|
              word.as_json.merge(
                meanings: word.meanings.sort_by(&:display_order).as_json,
                examples: word.examples.sort_by(&:display_order).as_json
              )
            end
          }
        end
      end
    end
  end
end
