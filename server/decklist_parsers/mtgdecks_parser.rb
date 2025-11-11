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

    def deck_name
      match = deck_header.text.match(/(?:MTG Arena)?(.*) deck, by(.*)/)
      match[1].strip
    end

    def author
      match = deck_header.text.match(/(?:MTG Arena)?(.*) deck, by(.*)/)
      match[2].strip
    end

    def card_hashes
      decklist_element = doc.css("textarea#arena_deck").first

      DecklistParsers::TextListParser.parse_decklist(decklist_element.text)
    end

    def source_type
      :mtg_decks
    end

    private

    def deck_header
      @deck_header ||= doc.css("h1:has(+ div#deck-tags-area)")
    end

    def doc
      if @doc
        @doc
      else
        response = Faraday.get(url)
        @doc = Nokogiri.HTML(response.body)
      end
    end
  end
end
