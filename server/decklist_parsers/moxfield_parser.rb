# frozen_string_literal: true
require "faraday"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class MoxfieldParser < DecklistParser
    def self.can_handle_url?(url)
      url.match?(%r{(?:https?://)?moxfield\.com/decks/.*})
    end

    def load_deck
      deck_id =
        %r{(?:https?://)?moxfield\.com/decks/(.*)}.match(url).captures.first

      deck_data = api.get("https://api.moxfield.com/v2/decks/all/#{deck_id}")

      name = deck_data.body["name"]
      author = deck_data.body["authors"].map { |u| u["displayName"] }.join(", ")

      main_deck_cards =
        deck_data.body["mainboard"].values.map do |v|
          card_to_hash(card_data: v)
        end
      sideboard_cards =
        deck_data.body["sideboard"].values.map do |v|
          card_to_hash(card_data: v)
        end
      main_deck = fetch_cards(card_hashes: main_deck_cards)
      sideboard = fetch_cards(card_hashes: sideboard_cards)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :moxfield,
        source_url: url,
        main_deck: main_deck,
        sideboard: sideboard
      )
    end

    private

    def fetch_cards(card_hashes:)
      cards_service = CardsService.new(redis: redis)

      cards = cards_service.get_cards(card_hashes: card_hashes)

      fetched_deck =
        card_hashes.map do |h|
          key = h.except(:quantity)

          card = cards[key]
          { quantity: h[:quantity], card: card }
        end
      quantities = {}
      fetched_deck.each_with_object(quantities) do |card, quantities|
        card_name = card[:card].name
        if quantities.key?(card_name)
          quantities[card_name] += card[:quantity]
        else
          quantities[card_name] = card[:quantity]
        end
      end

      cards = fetched_deck.map { |h| h[:card] }.uniq { |c| c.name }

      { quantities:, cards: }
    end

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

    def api
      options = { headers: { "user-agent" => ENV["MOXFIELD_USER_AGENT"] } }
      @api ||= Faraday.new(url, options) { |f| f.response :json }
    end
  end
end
