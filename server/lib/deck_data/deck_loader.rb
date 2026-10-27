# frozen_string_literal: true
require_relative "./errors"
require_relative "./sources/source_def"
require_relative "./sources/deck_source"
require_relative "./fetchers/moxfield_fetcher"
require_relative "./parsers/moxfield_parser"
require_relative "./fetchers/aetherhub_fetcher"
require_relative "./parsers/aetherhub_parser"
require_relative "../../services/deck_service"

module DeckData
  class DeckLoader
    SOURCE_DEFINITIONS = [
      DeckData::Sources::SourceDef.new(
        type: :moxfield,
        url_pattern: %r{(?:https?://)?moxfield\.com/decks/(?<id>[^/?#]+)},
        fetcher_class: DeckData::Fetchers::MoxfieldFetcher,
        parser_class: DeckData::Parsers::MoxfieldParser
      ),
      DeckData::Sources::SourceDef.new(
        type: :aetherhub,
        url_pattern: %r{(?:https?://)?aetherhub\.com/Deck/.*},
        fetcher_class: DeckData::Fetchers::AetherhubFetcher,
        parser_class: DeckData::Parsers::AetherhubParser
      )
    ]

    def load_deck(url:)
      source_def = source_definition_for(url: url)
      source =
        DeckData::Sources::DeckSource.new(url: url, definition: source_def)

      deck_service = DeckService.new

      if deck_service.deck_exists?(source.deck_key)
        return deck_service.load_deck(source.deck_key)
      end

      deck_data = source.get_deck

      deck_service.save_deck(
        **deck_data,
        source_type: source_def.type,
        source_url: url,
        ttl: (5 * 60),
        deck_key: source.deck_key
      )
    end

    private

    def source_definition_for(url:)
      SOURCE_DEFINITIONS.find do |definition|
        definition.can_handle_url?(url)
      end or raise UnsupportedUrlError, url
    end
  end
end
