# frozen_string_literal: true

module DeckData
  module Sources
    class DeckSource
      def self.can_handle_url?(url)
        url.match?(self::URL_PATTERN)
      end

      attr_reader :definition, :deck, :url

      def initialize(url:, definition:)
        @definition = definition
        @url = url
      end

      def get_deck
        @deck ||=
          begin
            init_data =
              definition
                .url_pattern
                .match(url)
                .named_captures
                .transform_keys(&:to_sym)
            fetcher = definition.fetcher_class.new(url: url, **init_data)
            data = fetcher.deck_data
            parser = definition.parser_class.new(deck_data: data)

            parser.parsed_deck
          end
      end

      def deck_key
        "decks:#{url}"
      end
    end
  end
end
