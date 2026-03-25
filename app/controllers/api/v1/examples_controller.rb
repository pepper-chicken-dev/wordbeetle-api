module Api
  module V1
    class ExamplesController < ApplicationController
      before_action :set_word
      before_action :set_example, only: [ :show, :update, :destroy ]

      def index
        examples = @word.examples
        render json: examples
      end

      def show
        render json: @example
      end

      def create
        example = @word.examples.new(example_params)

        if example.save
          render json: example, status: :created
        else
          render json: { errors: example.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @example.update(example_params)
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

      def set_word
        @word = current_user.wordbooks.find(params[:wordbook_id]).words.find(params[:word_id])
      end

      def set_example
        @example = @word.examples.find(params[:id])
      end

      def example_params
        params.require(:example).permit(:sentence, :translation, :display_order)
      end
    end
  end
end
