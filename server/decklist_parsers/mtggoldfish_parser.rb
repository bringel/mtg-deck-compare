# frozen_string_literal: true
require "faraday"
require "nokogiri"
require "byebug"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"
require_relative "./text_list_parser"

module DecklistParsers
  class MtggoldfishParser < DecklistParser
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    def load_deck
      response = Faraday.get(url, {}, { "Accept" => "text/html" })
      doc = Nokogiri.HTML(response.body)

      name = extract_deck_name(doc)

      author = extract_author(doc)

      decklist_text = doc.css("input#deck_input_deck").first&.attr("value")

      cards = parse_decklist_text(decklist_text)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :mtggoldfish,
        source_url: url,
        main_deck: cards[:main_deck],
        sideboard: cards[:sideboard]
      )
    end

    private

    def extract_deck_name(doc)
      # Try h1.deck-view-title first (user decks)
      name = doc.css(".deck-container h1.title").first&.text&.strip

      name.sub(/\s+by\s+.+$/i, "").strip
    end

    def extract_author(doc)
      # Try to find author link in deck-view-author
      author_elem = doc.css(".deck-container span.author").first
      return author_elem.text.sub(/\s*by\s*/i, "").strip
    end

    def parse_decklist_text(text)
      unless text
        return(
          {
            main_deck: fetch_cards(card_hashes: []),
            sideboard: fetch_cards(card_hashes: [])
          }
        )
      end

      cards = DecklistParsers::TextListParser.parse_decklist(text)

      {
        main_deck: fetch_cards(card_hashes: cards[:main_deck]),
        sideboard: fetch_cards(card_hashes: cards[:sideboard])
      }
    end
  end
end
