# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"

module DecklistParsers
  class AetherhubParser < DecklistParser
    private

    def get_card_info(url)
      page_content = Faraday.get(url)
      doc = Nokogiri.HTML(page_content.body)

      deck_id = doc.css("[data-deckid].mtgaExport").first["data-deckid"]

      deck_response =
        Faraday.get(
          "https://aetherhub.com/Deck/FetchMtgaDeckJson",
          { "deckId" => deck_id, "lang" => 0, "simple" => false }
        )

      deck = JSON.parse(deck_response.body)

      main_deck = []
      sideboard = []

      category = ""
      deck["convertedDeck"].each do |card|
        category = card["name"] if card["quantity"].nil?

        if card["quantity"] && card["name"]
          if category.downcase == "deck"
            main_deck << card.except("cardId")
          elsif category.downcase == "sideboard"
            sideboard << card.except("cardId")
          end
        end
      end

      return { main_deck:, sideboard: }
    end
  end
end
