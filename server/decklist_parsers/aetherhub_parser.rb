# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class AetherhubParser < DecklistParser
    def self.can_handle_url?(url)
      url.match?(%r{(?:https?://)?aetherhub\.com/Deck/.*})
    end

    def load_deck
      @page_content = Faraday.get(@url)
      @doc = Nokogiri.HTML(@page_content.body)
      cards = get_card_info

      page_title = @doc.css("title").text
      name = page_title.split("-", 2).last.strip

      main_deck = fetch_deck(deck: cards[:main_deck])
      sideboard = fetch_deck(deck: cards[:sideboard])

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

      set_code_conversions = {
        "dar" => "dom" # for some reason, some cards from Dominaria show up with the code DAR, but scryfall doesn't like it
      }

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

      main_deck =
        main_deck.map do |c|
          if set_code_conversions.key?(c["set"].downcase)
            c.merge({ "set" => set_code_conversions[c["set"].downcase] })
          else
            c
          end
        end

      sideboard =
        sideboard.map do |c|
          if set_code_conversions.key?(c["set"].downcase)
            c.merge({ "set" => set_code_conversions[c["set"].downcase] })
          else
            c
          end
        end

      return { main_deck:, sideboard: }
    end

    def fetch_deck(deck:)
      cards_service = CardsService.new

      fetched_deck =
        deck.map do |c|
          card =
            cards_service.get_card_from_set(
              set_code: c["set"].downcase,
              set_number: c["number"].to_i
            )
          { quantity: c["quantity"], card: card }
        end

      quantities = {}
      fetched_deck.each_with_object(quantities) do |c, quantities|
        card_name = c.dig(:card, :name)
        if quantities.key?(card_name)
          quantities[card_name] += c[:quantity]
        else
          quantities[card_name] = c[:quantity]
        end
      end

      cards = fetched_deck.map { |c| c[:card] }.uniq { |c| c[:name] }

      { quantities:, cards: }
    end
  end
end
