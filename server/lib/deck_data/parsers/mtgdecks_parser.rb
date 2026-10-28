# frozen_string_literal: true

require_relative "./parser"
require_relative "../../../decklist_parsers/text_list_parser"

module DeckData
  module Parsers
    class MtgDecksParser < Parser
      def deck_name
        match = deck_header.text.match(/(?:MTG Arena)?(.*) deck, by(.*)/)
        match[1].strip
      end

      def author
        match = deck_header.text.match(/(?:MTG Arena)?(.*) deck, by(.*)/)
        match[2].strip
      end

      def card_hashes
        decklist_element = deck_data.css("textarea#arena_deck").first

        DecklistParsers::TextListParser.parse_decklist(decklist_element.text)
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end

      private

      def deck_header
        @deck_header ||= deck_data.css("h1:has(+ div#deck-tags-area)")
      end
    end
  end
end
