# frozen_string_literal: true
require_relative "./errors"
require_relative "./sources/source_def"
require_relative "./sources/deck_source"
require_relative "./fetchers/moxfield_fetcher"
require_relative "./parsers/moxfield_parser"
require_relative "./fetchers/aetherhub_fetcher"
require_relative "./parsers/aetherhub_parser"
require_relative "./fetchers/archidekt_fetcher"
require_relative "./parsers/archidekt_parser"
require_relative "./fetchers/deckstats_fetcher"
require_relative "./parsers/deckstats_parser"
require_relative "./fetchers/mtggoldfish_fetcher"
require_relative "./parsers/mtggoldfish_parser"
require_relative "./fetchers/mtgdecks_fetcher"
require_relative "./parsers/mtgdecks_parser"
require_relative "../../services/deck_service"

module DeckData
  class DeckLoader
    MANUAL_DECK_PATTERN = %r{mtg-deck-compare://manualDeck/(?<id>.+)}

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
      ),
      DeckData::Sources::SourceDef.new(
        type: :archidekt,
        url_pattern: %r{(?:https?://)?archidekt\.com/decks/(?<id>\d+)},
        fetcher_class: DeckData::Fetchers::ArchidektFetcher,
        parser_class: DeckData::Parsers::ArchidektParser
      ),
      DeckData::Sources::SourceDef.new(
        type: :deckstats,
        url_pattern:
          %r{(?:https?://)?deckstats\.net/decks/(?<user_id>\d+)/(?<deck_id>[^/?#]+)},
        fetcher_class: DeckData::Fetchers::DeckstatsFetcher,
        parser_class: DeckData::Parsers::DeckstatsParser
      ),
      DeckData::Sources::SourceDef.new(
        type: :mtggoldfish,
        # Matches both user decks and archetype decks
        # User deck: https://www.mtggoldfish.com/deck/1234567
        # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
        url_pattern:
          %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+},
        fetcher_class: DeckData::Fetchers::MtggoldfishFetcher,
        parser_class: DeckData::Parsers::MtggoldfishParser
      ),
      DeckData::Sources::SourceDef.new(
        type: :mtg_decks,
        url_pattern: %r{(?:https?://)?(?:www\.)?mtgdecks.net/\w+/(.+)},
        fetcher_class: DeckData::Fetchers::MtgDecksFetcher,
        parser_class: DeckData::Parsers::MtgDecksParser
      )
    ]

    def load_deck(url:)
      if (manual_match = MANUAL_DECK_PATTERN.match(url))
        return load_manual_deck(manual_match[:id])
      end

      source_def = source_definition_for(url: url)
      source =
        DeckData::Sources::DeckSource.new(url: url, definition: source_def)

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

    def deck_service
      @deck_service ||= DeckService.new
    end

    def load_manual_deck(deck_id)
      unless deck_service.manual_deck_exists?(deck_id)
        raise DeckNotFoundError, deck_id
      end

      deck_service.load_manual_deck(deck_id)
    end

    def source_definition_for(url:)
      SOURCE_DEFINITIONS.find do |definition|
        definition.can_handle_url?(url)
      end or raise UnsupportedUrlError, url
    end
  end
end
