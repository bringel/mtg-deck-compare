# frozen_string_literal: true

require_relative "./parser"

module DeckData
  module Parsers
    class AetherhubParser < Parser
      SET_CODE_CONVERSIONS = {
        "dar" => "dom" # for some reason, some cards from Dominaria show up with the code DAR, but scryfall doesn't like it
      }.freeze

      def deck_name
        page_title = page.css("title").text
        page_title.split("-", 2).last.gsub(/youtube video/i, "").strip
      end

      def author
        page.css('a[href^="/User"]').first.text.strip
      end

      def card_hashes
        main_deck = []
        sideboard = []

        category = nil
        deck_json["convertedDeck"].each do |card|
          category = card["name"]&.downcase if card["quantity"].nil?
          next unless card["quantity"] && card["name"]

          case category
          when "deck", "commander"
            main_deck << card_to_hash(card_data: card)
          when "sideboard"
            sideboard << card_to_hash(card_data: card)
          end
        end

        { main_deck:, sideboard: }
      end

      def parsed_deck
        { name: deck_name, author: author, card_hashes: card_hashes }
      end

      private

      def page
        deck_data[:page]
      end

      def deck_json
        deck_data[:deck_json]
      end

      def card_to_hash(card_data:)
        if card_data["number"].nil? || card_data["number"].match?(/\d+-\w+/) ||
             card_data["number"].to_i > 9999
          # for some reason, there are some cards with "numbers" like 999-AC or 999-E
          # or the number is greater than 4 digits which shouldn't be possible right now
          # but currently is on aether hub for pioneer masters
          # I think maybe they're older alchemy cards that aetherhub is representing wierdly
          # if that's the case scryfall wont find them so we can just search them by name
          { name: card_data["name"], quantity: card_data["quantity"] }
        else
          set_code = card_data["set"].downcase
          {
            set_code: SET_CODE_CONVERSIONS.fetch(set_code, set_code),
            set_number: card_data["number"].to_i,
            quantity: card_data["quantity"]
          }
        end
      end
    end
  end
end
