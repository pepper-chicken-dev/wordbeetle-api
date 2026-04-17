module Api
  module V1
    class MeaningsController < ApplicationController
      before_action :set_word
      before_action :set_meaning, only: %i[show update destroy]

      def index
        meanings = @word.meanings
        render json: MeaningResource.new(meanings).serialize
      end

      def show
        render json: MeaningResource.new(@meaning).serialize
      end

      def create
        meaning = @word.meanings.new(meaning_params)
        meaning.save!
        render json: MeaningResource.new(meaning).serialize, status: :created
      end

      def update
        @meaning.update!(meaning_params)
        render json: MeaningResource.new(@meaning).serialize
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
        params.expect(meaning: %i[definition display_order])
      end
    end
  end
end
