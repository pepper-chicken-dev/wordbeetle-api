module Api
  module V1
    class WordbooksController < ApplicationController
      before_action :set_wordbook, only: %i[show update destroy]

      def index
        wordbooks = current_user.wordbooks
        render json: WordbookResource.new(wordbooks).serialize
      end

      def show
        render json: WordbookResource.new(@wordbook).serialize
      end

      def create
        wordbook = current_user.wordbooks.new(wordbook_params)
        wordbook.save!
        render json: WordbookResource.new(wordbook).serialize, status: :created
      end

      def update
        @wordbook.update!(wordbook_params)
        render json: WordbookResource.new(@wordbook).serialize
      end

      def destroy
        @wordbook.destroy
        head :no_content
      end

      private

      def set_wordbook
        @wordbook = current_user.wordbooks.find(params[:id])
      end

      def wordbook_params
        params.expect(wordbook: [:title])
      end
    end
  end
end
