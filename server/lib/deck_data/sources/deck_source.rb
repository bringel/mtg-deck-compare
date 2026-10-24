# frozen_string_literal: true

module DeckData
  module Sources
    class DeckSource
      def self.can_handle_url?(url)
        url.match?(self::URL_PATTERN)
      end

      def self.fetcher_class
        raise NotImplementedError
      end

      def self.parser_class
        raise NotImplementedError
      end

      attr_reader :url, :deck

      def initialize(url:)
        @url = url
      end

      def get_deck
        if @deck
          @deck
        else
          init_data =
            self.class::URL_PATTERN
              .match(url)
              .named_captures
              .transform_keys(&:to_sym)
          fetcher = self.class.fetcher_class.new(url: url, **init_data)
          data = fetcher.deck_data
          parser = self.class.parser_class.new(deck_data: data)

          parsed_data = parser.parsed_deck

          @deck = {
            **parsed_data,
            source_type: self.class.to_s,
            source_url: url,
            ttl: (5 * 60),
            deck_key: deck_key
          }
        end
      end

      def deck_key
        "decks:#{url}"
      end
    end
  end
end
