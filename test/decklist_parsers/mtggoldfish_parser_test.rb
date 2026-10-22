# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/decklist_parsers/mtggoldfish_parser"

class MtggoldfishParserTest < Minitest::Test
  include FixtureHelpers

  DECK_URL = "https://www.mtggoldfish.com/deck/7995961"
  DOWNLOAD_URL = "https://www.mtggoldfish.com/deck/download/7995961"
  ARCHETYPE_URL =
    "https://www.mtggoldfish.com/archetype/standard-azorius-control-woe"

  def blocked
    DecklistParsers::SourceBlockedError.new("blocked")
  end

  def test_matches_deck_and_archetype_urls
    parser = DecklistParsers::MtggoldfishParser

    assert parser.can_handle_url?(DECK_URL)
    assert parser.can_handle_url?("mtggoldfish.com/deck/7995961#paper")
    assert parser.can_handle_url?(ARCHETYPE_URL)
    refute parser.can_handle_url?("https://www.mtggoldfish.com/metagame/standard")
  end

  def test_parses_a_user_deck_page
    fetcher =
      FakeFetcher.new(
        DECK_URL => ok_response(fixture("mtggoldfish/deck_7995961.html"))
      )

    deck = DecklistParsers::MtggoldfishParser.new(DECK_URL, fetcher:).parse

    assert_equal "Azorius Control", deck.name
    assert_equal "junsei yamaguchi", deck.author
    assert_equal 60, deck.main_deck.sum { _1[:quantity] }
    assert_equal 15, deck.sideboard.sum { _1[:quantity] }
    assert_includes deck.main_deck, { quantity: 4, name: "Erode" }
  end

  def test_parses_an_archetype_page
    fetcher =
      FakeFetcher.new(
        ARCHETYPE_URL =>
          ok_response(
            fixture(
              "mtggoldfish/archetype_standard-azorius-control-woe.html"
            )
          )
      )

    deck = DecklistParsers::MtggoldfishParser.new(ARCHETYPE_URL, fetcher:).parse

    assert_equal "Azorius Control", deck.name
    assert_equal "jvoight0199", deck.author
    assert_equal 60, deck.main_deck.sum { _1[:quantity] }
    assert_equal 15, deck.sideboard.sum { _1[:quantity] }
    assert_includes deck.sideboard, { quantity: 2, name: "Rest in Peace" }
  end

  def test_falls_back_to_the_text_download_when_the_page_is_blocked
    download =
      ok_response(
        fixture("mtggoldfish/download_7995961.txt"),
        headers: {
          "Content-Disposition" =>
            'attachment; filename="Deck - Azorius Control.txt"; filename*=UTF-8\'\'Deck%20-%20Azorius%20Control.txt'
        }
      )
    fetcher = FakeFetcher.new(DECK_URL => blocked, DOWNLOAD_URL => download)

    deck =
      DecklistParsers::MtggoldfishParser.new(
        "https://www.mtggoldfish.com/deck/7995961#paper",
        fetcher:
      ).parse

    assert_equal "Azorius Control", deck.name
    assert_nil deck.author
    assert_equal 60, deck.main_deck.sum { _1[:quantity] }
    assert_equal 15, deck.sideboard.sum { _1[:quantity] }
    assert_equal :text, fetcher.requests.last[:accept]
  end

  def test_blocked_archetype_page_has_nothing_to_fall_back_to
    fetcher = FakeFetcher.new(ARCHETYPE_URL => blocked)

    assert_raises(DecklistParsers::SourceBlockedError) do
      DecklistParsers::MtggoldfishParser.new(ARCHETYPE_URL, fetcher:).parse
    end
  end

  def test_page_without_a_decklist_is_an_extraction_error
    fetcher = FakeFetcher.new(DECK_URL => ok_response("<html><body></body></html>"))

    error =
      assert_raises(DecklistParsers::ExtractionError) do
        DecklistParsers::MtggoldfishParser.new(DECK_URL, fetcher:).parse
      end
    assert_equal DOWNLOAD_URL, error.fallback_url
  end

  def test_fallback_url_is_the_text_export_when_the_id_is_known
    parser = DecklistParsers::MtggoldfishParser

    assert_equal DOWNLOAD_URL,
                 parser.new(DECK_URL, fetcher: FakeFetcher.new).fallback_url
    assert_equal ARCHETYPE_URL,
                 parser.new(ARCHETYPE_URL, fetcher: FakeFetcher.new).fallback_url
  end
end
