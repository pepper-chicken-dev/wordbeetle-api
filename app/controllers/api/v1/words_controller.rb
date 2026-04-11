module Api
  module V1
    class WordsController < ApplicationController
      before_action :set_wordbook
      before_action :set_word, only: %i[show update destroy]

      def index
        words = @wordbook.words.includes(:first_meaning)
        render json: WordResource.new(words, params: { include_first_meaning: true }).serialize
      end

      def show
        includes = parse_includes
        @word = @wordbook.words.includes(*includes.map(&:to_sym)).find(params[:id]) if includes.any?
        render json: WordResource.new(@word, params: { includes: includes }).serialize
      end

      def create
        word = @wordbook.words.new(word_params)

        if word.save
          render json: WordResource.new(word).serialize, status: :created
        else
          render json: { errors: word.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @word.update(word_params)
          render json: WordResource.new(@word).serialize
        else
          render json: { errors: @word.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @word.destroy
        head :no_content
      end

      ALLOWED_INCLUDES = %w[meanings examples].freeze

      private

      def set_wordbook
        @wordbook = current_user.wordbooks.find(params[:wordbook_id])
      end

      def set_word
        @word = @wordbook.words.find(params[:id])
      end

      def parse_includes
        return [] if params[:include].blank?

        params[:include].split(',').map(&:strip).select { |i| ALLOWED_INCLUDES.include?(i) }
      end

      def word_params
        params.expect(word: %i[spelling status next_review_at])
      end
    end
  end
end
