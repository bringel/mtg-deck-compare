# frozen_string_literal: true

module DeckData
  module Sources
    class DeckSource
      attr_reader :definition, :deck, :url

      def initialize(url:, definition:)
        @definition = definition
        @url = url
      end

      def get_deck
        @deck ||=
          begin
            fetcher = definition.fetcher_class.new(url: url, **url_params)
            data = fetcher.deck_data
            parser = definition.parser_class.new(deck_data: data)

            parser.parsed_deck
          end
      end

      def deck_key
        ["decks", definition.type, *url_params.values].join(":")
      end

      private

      def url_params
        @url_params ||=
          definition
            .url_pattern
            .match(url)
            .named_captures
            .transform_keys(&:to_sym)
      end
    end
  end
end
