module Api
  module V1
    class WordsController < ApplicationController
      before_action :set_word, only: [ :show, :update, :destroy ]

      def index
        words = Word.all
        render json: words
      end

      def show
        render json: @word
      end

      def create
        word = Word.new(word_params)

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

      def set_word
        @word = Word.find(params[:id])
      end

      def word_params
        params.require(:word).permit(:wordbook_id, :spelling, :status, :next_review_at)
      end
    end
  end
end
