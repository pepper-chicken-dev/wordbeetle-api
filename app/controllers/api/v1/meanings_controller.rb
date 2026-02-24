module Api
  module V1
    class MeaningsController < ApplicationController
      before_action :set_meaning, only: [ :show, :update, :destroy ]

      def index
        meanings = Meaning.all
        render json: meanings
      end

      def show
        render json: @meaning
      end

      def create
        meaning = Meaning.new(meaning_params)

        if meaning.save
          render json: meaning, status: :created
        else
          render json: { errors: meaning.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @meaning.update(meaning_params)
          render json: @meaning
        else
          render json: { errors: @meaning.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @meaning.destroy
        head :no_content
      end

      private

      def set_meaning
        @meaning = Meaning.find(params[:id])
      end

      def meaning_params
        params.require(:meaning).permit(:word_id, :content, :display_order)
      end
    end
  end
end
