module Api
  module V1
    class WordsController < ApplicationController
      before_action :set_wordbook
      before_action :set_word, only: %i[show update destroy]

      def index
        words = @wordbook.words.includes(:first_meaning)
        render_paginated(words, WordResource, params: { include_first_meaning: true })
      end

      def show
        render json: WordResource.new(@word, params: { includes: parse_includes }).serialize
      end

      def create
        word = @wordbook.words.new(create_word_params)
        word.save!
        render json: WordResource.new(word, params: { includes: %w[meanings examples] }).serialize, status: :created
      end

      def update
        @word.update!(update_word_params)
        render json: WordResource.new(@word).serialize
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
        includes = parse_includes
        scope = @wordbook.words
        if includes.include?('examples')
          scope = scope.includes(meanings: :examples)
        elsif includes.include?('meanings')
          scope = scope.includes(:meanings)
        end
        @word = scope.find(params[:id])
      end

      def parse_includes
        return [] if params[:include].blank?

        params[:include].split(',').map(&:strip).select { |i| ALLOWED_INCLUDES.include?(i) }
      end

      def create_word_params
        params.expect(word: [
                        :spelling,
                        { meanings_attributes: [[:definition, :display_order,
                                                 { examples_attributes: [%i[sentence translation display_order]] }]] }
                      ])
      end

      def update_word_params
        params.expect(word: [
                        :spelling, :status,
                        { meanings_attributes: [
                          [:id, :definition, :display_order,
                           { examples_attributes: [%i[id sentence translation display_order]] }]
                        ] }
                      ])
      end
    end
  end
end
