module Api
  module V1
    class ExamplesController < ApplicationController
      before_action :set_example, only: [ :show, :update, :destroy ]

      def index
        examples = Example.joins(word: :wordbook).where(wordbooks: { user_id: current_user.id })
        render json: examples
      end

      def show
        render json: @example
      end

      def create
        word = Word.joins(:wordbook).where(wordbooks: { user_id: current_user.id }).find(example_params[:word_id])
        example = word.examples.new(example_params.except(:word_id))

        if example.save
          render json: example, status: :created
        else
          render json: { errors: example.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @example.update(example_params.except(:word_id))
          render json: @example
        else
          render json: { errors: @example.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @example.destroy
        head :no_content
      end

      private

      def set_example
        @example = Example.joins(word: :wordbook).where(wordbooks: { user_id: current_user.id }).find(params[:id])
      end

      def example_params
        params.require(:example).permit(:word_id, :sentence, :translation, :display_order)
      end
    end
  end
end
