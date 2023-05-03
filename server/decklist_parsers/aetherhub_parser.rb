# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class AetherhubParser < DecklistParser
    def load_deck
      @page_content = Faraday.get(@url)
      @doc = Nokogiri.HTML(@page_content.body)
      cards = get_card_info

      page_title = @doc.css("title").text
      name = page_title.split("-", 2).last.strip

      card_lookup =
        Proc.new do |c|
          cards_service = CardsService.new
          card =
            cards_service.get_card_from_set(
              set_code: c["set"].downcase,
              set_number: c["number"].to_i
            )
          puts card
          { quantity: c["quantity"], card: card }
        end
      main_deck = cards[:main_deck].map(&card_lookup)
      sideboard = cards[:sideboard].map(&card_lookup)

      Models::Deck.new(
        name: name,
        source_type: :aetherhub,
        source_url: @url,
        main_deck: main_deck,
        sideboard: sideboard
      )
    end

    private

    def get_card_info
      deck_id = @doc.css("[data-deckid].mtgaExport").first["data-deckid"]

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
