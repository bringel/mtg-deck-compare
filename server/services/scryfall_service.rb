# frozen_string_literal: true
require "faraday"
require "json"

require_relative "../models/card"

class ScryfallService
  def initialize
    @api = Faraday.new(url: "https://api.scryfall.com")
  end

  def get_card_from_set(set_code:, set_number:)
    res = @api.get("cards/#{set_code.downcase}/#{set_number}")

    response_data = JSON.parse(res.body)

    mana_cost = response_data["mana_cost"]
    card_image_url = response_data.dig("image_uris", "large")
    card_art_url = response_data.dig("image_uris", "art_crop")
    card_layout_type = response_data["layout"]

    if card_layout_type == "transform"
      face = response_data["card_faces"].first
      mana_cost = face["mana_cost"]
      card_image_url = face.dig("image_uris", "large")
      card_art_url = face.dig("image_uris", "art_crop")
    elsif card_layout_type == "modal_dfc"
      mana_cost =
        "#{response_data["card_faces"].first["mana_cost"]} / #{response_data["card_faces"].last["mana_cost"]}"
      #TODO: handle multiple faces artwork
      card_image_url =
        response_data["card_faces"].first.dig("image_uris", "large")
      card_art_url =
        response_data["card_faces"].first.dig("image_uris", "art_crop")
    end

    Models::Card.new(
      card_id: nil,
      name: response_data["name"],
      set_code: response_data["set"],
      set_number: response_data["collector_number"],
      mana_cost: mana_cost,
      converted_mana_cost: response_data["cmc"],
      card_image_url: card_image_url,
      card_art_url: card_art_url,
      oracle_id: response_data["oracle_id"],
      multiverse_ids: response_data["multiverse_ids"],
      scryfall_url: response_data["scryfall_uri"]
    )
  end
end
