# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/lib/deck_url"

class DeckUrlTest < Minitest::Test
  def test_adds_a_scheme_and_forces_https
    assert_equal "https://archidekt.com/decks/1", DeckUrl.normalize("archidekt.com/decks/1")
    assert_equal "https://archidekt.com/decks/1", DeckUrl.normalize("http://archidekt.com/decks/1")
  end

  def test_drops_fragments_trailing_slashes_and_whitespace
    assert_equal "https://www.mtggoldfish.com/deck/123",
                 DeckUrl.normalize("  https://WWW.MTGGoldfish.com/deck/123/#paper ")
  end

  def test_keeps_query_strings
    assert_equal "https://deckstats.net/decks/1/2-x?share_key=abc",
                 DeckUrl.normalize("https://deckstats.net/decks/1/2-x?share_key=abc")
  end

  def test_leaves_manual_deck_urls_alone
    url = "mtg-deck-compare://manualDeck/123e4567"
    assert_equal url, DeckUrl.normalize(url)
  end

  def test_garbage_is_an_unsupported_url
    assert_raises(DecklistParsers::UnsupportedUrlError) { DeckUrl.normalize("not a url") }
    assert_raises(DecklistParsers::UnsupportedUrlError) { DeckUrl.normalize("") }
  end
end
