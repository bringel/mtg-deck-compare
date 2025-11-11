# frozen_string_literal: true
require "faraday"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class MoxfieldParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?moxfield\.com/decks/(.*)}

    def deck_name
      deck_data["name"]
    end

    def author
      deck_data["authors"].map { |u| u["displayName"] }.join(", ")
    end

    def card_hashes
      {
        main_deck:
          deck_data["mainboard"].values.map { |v| card_to_hash(card_data: v) },
        sideboard:
          deck_data["sideboard"].values.map { |v| card_to_hash(card_data: v) }
      }
    end

    def source_type
      :moxfield
    end

    private

    def deck_data
      if @deck_data
        @deck_data
      else
        deck_id = URL_PATTERN.match(url).captures.first
        response = api.get("https://api.moxfield.com/v2/decks/all/#{deck_id}")
        @deck_data = response.body
      end
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
