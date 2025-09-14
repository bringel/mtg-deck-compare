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
    card_image_urls = [response_data.dig("image_uris", "large")]
    card_art_urls = [response_data.dig("image_uris", "art_crop")]
    card_layout_type = response_data["layout"]
    card_type = parse_card_type(type_line: response_data["type_line"])

    if card_layout_type == "transform"
      faces = response_data["card_faces"]
      mana_cost = faces.first["mana_cost"]
      card_image_urls = faces.map { |f| f.dig("image_uris", "large") }
      card_art_urls = faces.map { |f| f.dig("image_uris", "art_crop") }
      card_type = parse_card_type(type_line: faces.first["type_line"])
    elsif card_layout_type == "modal_dfc"
      mana_cost =
        "#{response_data["card_faces"].first["mana_cost"]} / #{response_data["card_faces"].last["mana_cost"]}"
      card_image_urls = faces.map { |f| f.dig("image_uris", "large") }
      card_art_urls = faces.map { |f| f.dig("image_uris", "art_crop") }
      card_type = parse_card_type(type_line: faces.first["type_line"])
    end

    Models::Card.new(
      name: response_data["name"],
      set_code: response_data["set"],
      set_number: response_data["collector_number"],
      mana_cost: mana_cost,
      converted_mana_cost: response_data["cmc"],
      card_image_urls: card_image_urls,
      card_art_urls: card_art_urls,
      oracle_id: response_data["oracle_id"],
      multiverse_ids: response_data["multiverse_ids"],
      scryfall_url: response_data["scryfall_uri"],
      rarity: response_data["rarity"],
      card_type: card_type
    )
  end

  private

  def parse_card_type(type_line:)
    matcher =
      /(artifact|battle|creature|enchantment|instant|land|planeswalker|sorcery)/i

    matcher.match(type_line)&.captures[0].downcase.to_sym
  end
end
