module Api
  module V1
    class WordbooksController < ApplicationController
      before_action :set_wordbook, only: [:show, :update, :destroy]

      def index
        wordbooks = Wordbook.all
        render json: wordbooks
      end

      def show
        render json: @wordbook
      end

      def create
        wordbook = Wordbook.new(wordbook_params)

        if wordbook.save
          render json: wordbook, status: :created
        else
          render json: { errors: wordbook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @wordbook.update(wordbook_params)
          render json: @wordbook
        else
          render json: { errors: @wordbook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @wordbook.destroy
        head :no_content
      end

      private

      def set_wordbook
        @wordbook = Wordbook.find(params[:id])
      end

      def wordbook_params
        params.require(:wordbook).permit(:user_id, :title)
      end
    end
  end
end
