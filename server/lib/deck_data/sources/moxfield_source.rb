# frozen_string_literal: true

require_relative "./deck_source"
require_relative "../fetchers/moxfield_fetcher"

module DeckData
  module Sources
    class MoxfieldSource < DeckSource
      URL_PATTERN = %r{(?:https?://)?moxfield\.com/decks/(?<id>.*)}

      def self.fetcher_class
        ::DeckData::Fetchers::MoxfieldFetcher
      end
    end
  end
end
