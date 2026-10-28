# frozen_string_literal: true

require_relative "./parser"

module DeckData
  module Parsers
    class ArchidektParser < Parser
      def deck_name
        deck_data["name"]
      end

      def author
        deck_data.dig("owner", "username")
      end

      def card_hashes
        in_deck_categories =
          deck_data["categories"].filter_map do |cat|
            cat["name"] if cat["includedInDeck"]
          end

        sideboard_cards, main_deck_cards =
          deck_data["cards"]
            .filter do |card|
              card["categories"].any? { |cat| in_deck_categories.include?(cat) }
            end
            .partition { |card| card["categories"].include?("Sideboard") }

        {
          main_deck: main_deck_cards.map { |c| card_to_hash(card_data: c) },
          sideboard: sideboard_cards.map { |c| card_to_hash(card_data: c) }
        }
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end

      private

      def card_to_hash(card_data:)
        {
          set_code: card_data.dig("card", "edition", "editioncode"),
          set_number: card_data.dig("card", "collectorNumber").to_i,
          quantity: card_data["quantity"]
        }
      end
    end
  end
end
