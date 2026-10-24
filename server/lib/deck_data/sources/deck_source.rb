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
    end
  end
end
