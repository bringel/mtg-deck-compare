# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"
require_relative "./text_list_parser"

module DecklistParsers
  class MtgDecksParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?mtgdecks.net/\w+/(.+)}

    def load_deck
      response = Faraday.get(url)
      doc = Nokogiri.HTML(response.body)

      deck_header = doc.css("h1:has(+ div#deck-tags-area)")
      match = deck_header.text.match(/(?:MTG Arena)?(.*) deck, by(.*)/)

      name = match[1].strip
      author = match[2].strip

      decklist_element = doc.css("textarea#arena_deck").first

      parsed_list =
        DecklistParsers::TextListParser.parse_decklist(decklist_element.text)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :mtg_decks,
        source_url: url,
        main_deck: fetch_cards(card_hashes: parsed_list[:main_deck]),
        sideboard: fetch_cards(card_hashes: parsed_list[:sideboard])
      )
    end
  end
end
