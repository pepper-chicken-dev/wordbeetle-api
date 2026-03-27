module Api
  module V1
    class WordsController < ApplicationController
      before_action :set_wordbook
      before_action :set_word, only: [ :show, :update, :destroy ]

      def index
        words = @wordbook.words.includes(:first_meaning)
        render json: words.map { |word|
          word.as_json.merge(first_meaning: word.first_meaning&.as_json)
        }
      end

      def show
        render json: @word
      end

      def create
        word = @wordbook.words.new(word_params)

        if word.save
          render json: word, status: :created
        else
          render json: { errors: word.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @word.update(word_params)
          render json: @word
        else
          render json: { errors: @word.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @word.destroy
        head :no_content
      end

      private

      def set_wordbook
        @wordbook = current_user.wordbooks.find(params[:wordbook_id])
      end

      def set_word
        @word = @wordbook.words.find(params[:id])
      end

      def word_params
        params.require(:word).permit(:spelling, :status, :next_review_at)
      end
    end
  end
end
