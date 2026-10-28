# frozen_string_literal: true

require_relative "./parser"

module DeckData
  module Parsers
    class MoxfieldParser < Parser
      def deck_name
        deck_data["name"]
      end

      def author
        deck_data["authors"].map { |u| u["displayName"] }.join(", ")
      end

      def card_hashes
        {
          main_deck:
            deck_data["mainboard"].values.map do |v|
              card_to_hash(card_data: v)
            end,
          sideboard:
            deck_data["sideboard"].values.map { |v| card_to_hash(card_data: v) }
        }
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end

      private

      def card_to_hash(card_data:)
        if card_data.dig("card", "set") == "plst"
          set, number = card_data.dig("card", "cn").split("-")
        else
          set = card_data.dig("card", "set")
          number = card_data.dig("card", "cn")
        end
        {
          set_code: set.downcase,
          set_number: number.to_i,
          quantity: card_data["quantity"]
        }
      end
    end
  end
end
