# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/services/deck_service"

class DeckServiceTest < Minitest::Test
  include FixtureHelpers

  DECK_URL = "https://www.mtggoldfish.com/deck/7995961"

  # Resolves every card hash by name except the ones in `unknown`
  class FakeCardsService
    def initialize(unknown: [])
      @unknown = unknown
    end

    def get_cards(card_hashes:)
      card_hashes
        .reject { |h| @unknown.include?(h[:name]) }
        .to_h do |h|
          card = card_named(h[:name])
          [Models::CardKey.from_card_hash(h), card]
        end
    end

    def card_named(name)
      Models::Card.new(
        name: name,
        set_code: "tst",
        set_number: "1",
        mana_cost: nil,
        converted_mana_cost: 0,
        card_image_urls: [],
        card_art_urls: [],
        oracle_id: name,
        multiverse_ids: [],
        scryfall_url: nil,
        rarity: "common",
        card_type: "creature",
        layout: "normal"
      )
    end
  end

  # Swaps in a parser double for MtggoldfishParser for the duration of a test
  def with_parser(result, fallback_url: "https://example.com/fallback")
    parser_class = DecklistParsers::MtggoldfishParser
    original_new = parser_class.method(:new)
    calls = 0
    parser = Object.new
    parser.define_singleton_method(:parse) do
      calls += 1
      result.is_a?(Exception) ? raise(result) : result.call
    end
    parser.define_singleton_method(:source_type) { :mtggoldfish }
    parser.define_singleton_method(:fallback_url) { fallback_url }
    parser.define_singleton_method(:url) { DECK_URL }

    parser_class.define_singleton_method(:new) { |*_args, **_kwargs| parser }
    yield -> { calls }
  ensure
    parser_class.singleton_class.send(:remove_method, :new)
  end

  def parsed_deck
    -> do
      Models::ParsedDeck.from_sections(
        name: "Azorius Control",
        author: "someone",
        sections: {
          commander: [],
          main_deck: [{ quantity: 4, name: "Island" }, { quantity: 1, name: "Mystery Card" }],
          sideboard: [{ quantity: 2, name: "Negate" }]
        }
      )
    end
  end

  def setup
    @redis = FakeRedis.new
    @service =
      DeckService.new(
        redis: @redis,
        cards_service: FakeCardsService.new(unknown: ["Mystery Card"])
      )
  end

  def test_unsupported_urls_raise_a_typed_error
    assert_raises(DecklistParsers::UnsupportedUrlError) do
      @service.load_from_url("https://example.com/my-deck")
    end
  end

  def test_missing_manual_decks_raise_not_found
    error =
      assert_raises(DecklistParsers::DeckNotFoundError) do
        @service.load_from_url("mtg-deck-compare://manualDeck/nope")
      end
    assert_equal :manual, error.source_type
  end

  def test_loads_parses_and_caches_a_deck
    with_parser(parsed_deck) do |calls|
      deck = @service.load_from_url("www.mtggoldfish.com/deck/7995961#paper")

      assert_equal "Azorius Control", deck.name
      assert_equal DECK_URL, deck.source_url
      assert_equal({ "Island" => 4 }, deck.main_deck[:quantities])
      assert_equal({ "Negate" => 2 }, deck.sideboard[:quantities])

      # a differently written URL for the same deck hits the cache
      @service.load_from_url("https://www.mtggoldfish.com/deck/7995961/")
      assert_equal 1, calls.call
      assert_equal DeckService::FRESH_TTL, @redis.ttls["decks:#{DECK_URL}"]
      assert_equal DeckService::STALE_TTL, @redis.ttls["decks:stale:#{DECK_URL}"]
    end
  end

  def test_serves_the_stale_copy_when_a_refetch_is_blocked
    with_parser(parsed_deck) { @service.load_from_url(DECK_URL) }
    @redis.store.delete("decks:#{DECK_URL}") # fresh copy expired

    with_parser(DecklistParsers::SourceBlockedError.new("blocked")) do
      deck = @service.load_from_url(DECK_URL)
      assert_equal "Azorius Control", deck.name
    end
  end

  def test_does_not_serve_stale_copies_of_deleted_decks
    with_parser(parsed_deck) { @service.load_from_url(DECK_URL) }
    @redis.store.delete("decks:#{DECK_URL}")

    with_parser(DecklistParsers::DeckNotFoundError.new("gone")) do
      assert_raises(DecklistParsers::DeckNotFoundError) do
        @service.load_from_url(DECK_URL)
      end
    end
  end

  def test_errors_get_the_parsers_source_and_fallback_url
    with_parser(DecklistParsers::SourceBlockedError.new("blocked")) do
      error =
        assert_raises(DecklistParsers::SourceBlockedError) do
          @service.load_from_url(DECK_URL)
        end
      assert_equal :mtggoldfish, error.source_type
      assert_equal "https://example.com/fallback", error.fallback_url
    end
  end

  def test_unexpected_parser_crashes_become_extraction_errors
    with_parser(NoMethodError.new("undefined method `[]' for nil")) do
      error =
        assert_raises(DecklistParsers::ExtractionError) do
          @service.load_from_url(DECK_URL)
        end
      assert_equal :mtggoldfish, error.source_type
      assert_equal "https://example.com/fallback", error.fallback_url
    end
  end

  def test_an_empty_deck_is_an_extraction_error
    empty = -> { Models::ParsedDeck.new(name: "x", author: nil, main_deck: []) }

    with_parser(empty) do
      assert_raises(DecklistParsers::ExtractionError) do
        @service.load_from_url(DECK_URL)
      end
    end
  end

  def test_manual_decks_keep_commanders
    result =
      @service.save_manual_deck(
        name: "Manual",
        author: nil,
        list: "Commander\n1 Atraxa\nDeck\n1 Island"
      )

    assert_equal({ "Atraxa" => 1, "Island" => 1 }, result[:deck].main_deck[:quantities])

    loaded = @service.load_from_url("mtg-deck-compare://manualDeck/#{result[:deck_id]}")
    assert_equal "Manual", loaded.name
  end
end
