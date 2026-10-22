# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/decklist_parsers/moxfield_parser"

# Moxfield's API needs an approved user agent, so this uses a small hand-built
# payload with the same shape as /v2/decks/all/:id instead of a recorded one
class MoxfieldParserTest < Minitest::Test
  include FixtureHelpers

  API_URL = "https://api.moxfield.com/v2/decks/all/abc123"

  def entry(quantity, set, cn, name = "Card")
    { "quantity" => quantity, "card" => { "set" => set, "cn" => cn, "name" => name } }
  end

  def payload(overrides = {})
    {
      "name" => "Test Deck",
      "authors" => [{ "displayName" => "Ann" }, { "displayName" => "Bo" }],
      "commanders" => { "Atraxa" => entry(1, "ONE", "196") },
      "mainboard" => {
        "Sol Ring" => entry(1, "c21", "263"),
        "Listed" => entry(1, "plst", "ELD-123")
      },
      "sideboard" => {}
    }.merge(overrides)
  end

  def parse(data, url: "https://moxfield.com/decks/abc123")
    fetcher = FakeFetcher.new(API_URL => ok_response(JSON.generate(data)))
    DecklistParsers::MoxfieldParser.new(url, fetcher:).parse
  end

  def test_includes_commanders_in_the_main_deck
    deck = parse(payload)

    assert_equal "Test Deck", deck.name
    assert_equal "Ann, Bo", deck.author
    assert_includes deck.main_deck, { set_code: "one", set_number: 196, quantity: 1 }
    assert_includes deck.main_deck, { set_code: "c21", set_number: 263, quantity: 1 }
  end

  def test_the_list_cards_use_the_original_set
    deck = parse(payload)

    assert_includes deck.main_deck, { set_code: "eld", set_number: 123, quantity: 1 }
  end

  def test_deck_id_ignores_query_strings
    deck = parse(payload, url: "https://www.moxfield.com/decks/abc123?tab=stats")

    assert_equal "Test Deck", deck.name
  end

  def test_missing_authors_fall_back_to_the_creator
    deck =
      parse(
        payload(
          "authors" => nil,
          "createdByUser" => {
            "displayName" => "Creator"
          }
        )
      )

    assert_equal "Creator", deck.author
  end
end
