# frozen_string_literal: true

module DeckData
  module Parsers
    class HashParser
      attr_reader :deck_data

      def initialize(deck_data:)
        @deck_data = deck_data
      end

      def parsed_deck
        raise NotImplementedError
      end
    end
  end
end
