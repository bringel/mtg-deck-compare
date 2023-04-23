# frozen_string_literal: true
require "faraday"
require "json"

require_relative "../models/card"

class ScryfallService
  def initialize
    @api = Faraday.new(url: "https://api.scryfall.com")
  end

  def get_card_from_set(set_code:, set_number:)
    res = @api.get("cards/#{set_code}/#{set_number}")

    response_data = JSON.parse(res.body)
    Models::Card.new(
      card_id: nil,
      name: response_data["name"],
      set_code: response_data["set"],
      set_number: response_data["collector_number"],
      mana_cost: response_data["mana_cost"],
      converted_mana_cost: response_data["cmc"],
      card_image_url: response_data.dig("image_uris", "large"),
      card_art_url: response_data.dig("image_uris", "art_crop"),
      oracle_id: response_data["oracle_id"],
      multiverse_ids: response_data["multiverse_ids"],
      scryfall_url: response_data["scryfall_uri"]
    )
  end
end
