# frozen_string_literal: true
require "json"

require_relative "./parser"
require_relative "../errors"

module DeckData
  module Parsers
    class DeckstatsParser < Parser
      def deck_name
        deck_json["name"]
      end

      def author
        author_from_data = deck_json.dig("saved_by", "username")
        author_from_link = user_link&.text
        author_from_link || author_from_data || "Unknown"
      end

      def card_hashes
        main_deck_cards = []
        sideboard_cards = []

        deck_json["sections"]&.each do |section|
          cards = section["cards"].map { |c| card_to_hash(card_data: c) }

          if section["name"] == "Sideboard"
            sideboard_cards.concat(cards)
          else
            main_deck_cards.concat(cards)
          end
        end

        { main_deck: main_deck_cards, sideboard: sideboard_cards }
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end

      private

      def page
        deck_data[:page]
      end

      def set_mappings
        deck_data[:set_mappings]
      end

      def deck_json
        @deck_json ||=
          begin
            script =
              page
                .css("script")
                .find { |s| s.content.include?("init_deck_data") }
            json_match =
              script&.content&.match(/init_deck_data\(({.*?}), false\);/m)

            unless json_match
              raise ParseError, "Could not find deck_data in page"
            end
            JSON.parse(json_match[1])
          end
      end

      def user_link
        user_href = "https://deckstats.net/decks/#{deck_data[:user_id]}"

        page
          .css("a[href^='#{user_href}']")
          .find { |anchor| anchor["href"].split("?").first == user_href }
      end

      def card_to_hash(card_data:)
        # Try to use set_code + collector_number if available
        set_id =
          card_data["set_id"]&.to_s ||
            card_data.dig("data", "display_set_id")&.to_s
        collector_number =
          card_data["collector_number"] ||
            card_data.dig("data", "collector_number")

        if set_id && collector_number && set_mappings[set_id]
          {
            set_code: set_mappings[set_id],
            set_number: collector_number.to_i,
            quantity: card_data["amount"]
          }
        else
          { name: card_data["name"], quantity: card_data["amount"] }
        end
      end
    end
  end
end
