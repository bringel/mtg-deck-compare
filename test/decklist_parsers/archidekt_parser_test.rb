# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/decklist_parsers/archidekt_parser"

class ArchidektParserTest < Minitest::Test
  include FixtureHelpers

  API_URL = "https://archidekt.com/api/decks/7031486/"

  def test_matches_urls_with_and_without_a_slug
    parser = DecklistParsers::ArchidektParser

    assert parser.can_handle_url?("https://archidekt.com/decks/7031486/buffs_by_hans")
    assert parser.can_handle_url?("https://archidekt.com/decks/7031486")
    assert parser.can_handle_url?("archidekt.com/decks/7031486/")
    refute parser.can_handle_url?("https://archidektXcom/decks/7031486")
  end

  def test_parses_a_commander_deck
    fetcher =
      FakeFetcher.new(API_URL => ok_response(fixture("archidekt/deck_7031486.json")))

    deck =
      DecklistParsers::ArchidektParser.new(
        "https://archidekt.com/decks/7031486",
        fetcher:
      ).parse

    assert_equal "Buffs by Hans", deck.name
    assert_equal "SalubriousSnail", deck.author
    assert_equal 100, deck.main_deck.sum { _1[:quantity] }
    assert_empty deck.sideboard
    assert deck.main_deck.all? { _1[:set_code] && _1[:set_number] }
    assert_equal :json, fetcher.requests.first[:accept]
  end
end
