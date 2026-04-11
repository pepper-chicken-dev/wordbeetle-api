module Api
  module V1
    class WordsController < ApplicationController
      before_action :set_wordbook
      before_action :set_word, only: %i[show update destroy]

      def index
        words = @wordbook.words.includes(:first_meaning)
        render json: words.map { |word|
          word.as_json(only: Word::API_FIELDS).merge(first_meaning: word.first_meaning&.as_json(only: [:definition]))
        }
      end

      def show
        includes = parse_includes
        @word = @wordbook.words.includes(*includes.map(&:to_sym)).find(params[:id]) if includes.any?
        render json: word_json(@word, includes: includes)
      end

      def create
        word = @wordbook.words.new(word_params)

        if word.save
          render json: word.as_json(only: Word::API_FIELDS), status: :created
        else
          render json: { errors: word.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @word.update(word_params)
          render json: @word.as_json(only: Word::API_FIELDS)
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

      def word_json(word, includes: [])
        json = word.as_json(only: Word::API_FIELDS)
        includes.each do |assoc|
          json[assoc] = word.public_send(assoc).sort_by(&:display_order).as_json
        end
        json
      end

      def word_params
        params.expect(word: %i[spelling status next_review_at])
      end
    end
  end
end
