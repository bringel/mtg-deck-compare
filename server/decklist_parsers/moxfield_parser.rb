# frozen_string_literal: true
require "faraday"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class MoxfieldParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?moxfield\.com/decks/(.*)}

    def load_deck
      deck_id = URL_PATTERN.match(url).captures.first

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
      @api ||=
        Faraday.new(url, options) do |f|
          f.use Middleware::RateLimiter,
                redis: ServiceRegistry.redis,
                requests: 1,
                period: 1,
                unit: :seconds
          f.response :json
        end
    end
  end
end
