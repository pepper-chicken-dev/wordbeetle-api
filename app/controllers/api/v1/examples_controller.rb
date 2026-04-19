module Api
  module V1
    class ExamplesController < ApplicationController
      before_action :set_word
      before_action :set_example, only: %i[show update destroy]

      def index
        examples = @word.examples
        render_paginated(examples, ExampleResource)
      end

      def show
        render json: ExampleResource.new(@example).serialize
      end

      def create
        example = @word.examples.new(example_params)
        example.save!
        render json: ExampleResource.new(example).serialize, status: :created
      end

      def update
        @example.update!(example_params)
        render json: ExampleResource.new(@example).serialize
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
        params.expect(example: %i[sentence translation display_order])
      end
    end
  end
end
