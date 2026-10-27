# frozen_string_literal: true

require_relative "./parser"
require_relative "../../../decklist_parsers/text_list_parser"

module DeckData
  module Parsers
    class MtggoldfishParser < Parser
      def deck_name
        name = deck_data.at_css(".deck-container h1.title").text.strip
        name.sub(/\s+by\s+.+$/i, "").strip
      end

      def author
        author_elem = deck_data.at_css(".deck-container span.author")
        author_elem.text.sub(/\s*by\s*/i, "").strip
      end

      def card_hashes
        decklist_text = deck_data.at_css("#deck_input_deck")&.[]("value")

        return { main_deck: [], sideboard: [] } unless decklist_text

        DecklistParsers::TextListParser.parse_decklist(decklist_text)
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end
    end
  end
end
