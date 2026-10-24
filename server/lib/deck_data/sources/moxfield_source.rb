# frozen_string_literal: true

require_relative "./deck_source"
require_relative "../fetchers/moxfield_fetcher"
require_relative "../parsers/moxfield_parser"

module DeckData
  module Sources
    class MoxfieldSource < DeckSource
      URL_PATTERN = %r{(?:https?://)?moxfield\.com/decks/(?<id>.*)}

      def self.fetcher_class
        ::DeckData::Fetchers::MoxfieldFetcher
      end

      def self.parser_class
        ::DeckData::Parsers::MoxfieldParser
      end
    end
  end
end
