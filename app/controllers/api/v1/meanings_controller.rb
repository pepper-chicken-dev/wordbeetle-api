module Api
  module V1
    class MeaningsController < ApplicationController
      before_action :set_word
      before_action :set_meaning, only: %i[show update destroy]

      def index
        meanings = @word.meanings
        render json: meanings
      end

      def show
        render json: @meaning
      end

      def create
        meaning = @word.meanings.new(meaning_params)

        if meaning.save
          render json: meaning, status: :created
        else
          render json: { errors: meaning.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @meaning.update(meaning_params)
          render json: @meaning
        else
          render json: { errors: @meaning.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @meaning.destroy
        head :no_content
      end

      private

      def set_word
        @word = current_user.wordbooks.find(params[:wordbook_id]).words.find(params[:word_id])
      end

      def set_meaning
        @meaning = @word.meanings.find(params[:id])
      end

      def meaning_params
        params.expect(meaning: %i[content display_order])
      end
    end
  end
end
