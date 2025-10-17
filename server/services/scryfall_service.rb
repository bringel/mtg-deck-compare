# frozen_string_literal: true
require "faraday"
require "json"

require_relative "../models/card"
require_relative "../middleware/rate_limiter"

class ScryfallService
  def initialize(redis: nil)
    @api = Faraday.new(url: "https://api.scryfall.com") do |f|
      if redis
        f.use Middleware::RateLimiter,
              redis: redis,
              requests: 10,
              period: 1,
              unit: :seconds
      end
      f.adapter Faraday.default_adapter
    end
  end

  def get_card_from_set(set_code:, set_number:)
    res = @api.get("cards/#{set_code.downcase}/#{set_number}")
    response_data = JSON.parse(res.body)
    parse_card_data(response_data)
  end

  def get_cards(card_hashes:)
    query_parts =
      card_hashes.map do |hash|
        if hash.has_key?(:name)
          # see note in aetherhub_parser.rb about why some cards may have just a name
          "(!\"#{hash[:name]}\")"
        else
          "(set:#{hash[:set_code]} number:#{hash[:set_number]})"
        end
      end

    card_data =
      query_parts
        .each_slice(20)
        .map do |queries|
          query = queries.join(" or ")

          res = @api.get("cards/search") { |req| req.params["q"] = query }

          response_data = JSON.parse(res.body)

          next {} unless response_data["data"]

          response_data["data"]
            .map { |card_data| parse_card_data(card_data) }
            .to_h do |card|
              [
                {
                  set_code: card.set_code.downcase,
                  set_number: card.set_number.to_i
                },
                card
              ]
            end
        end

    card_data.reduce({}, &:merge)
  end

  private

  def parse_card_data(response_data)
    name = response_data["name"]
    mana_cost = response_data["mana_cost"]
    card_image_urls = [response_data.dig("image_uris", "large")]
    card_art_urls = [response_data.dig("image_uris", "art_crop")]
    card_layout_type = response_data["layout"]
    card_type = parse_card_type(type_line: response_data["type_line"] || "")

    if card_layout_type == "transform" || card_layout_type == "reversible_card"
      faces = response_data["card_faces"]
      name = faces.map { |f| f["name"] }.join(" // ")
      mana_cost = faces.first["mana_cost"]
      card_image_urls = faces.map { |f| f.dig("image_uris", "large") }
      card_art_urls = faces.map { |f| f.dig("image_uris", "art_crop") }
      card_type = parse_card_type(type_line: faces.first["type_line"])
    elsif card_layout_type == "modal_dfc"
      name = faces.map { |f| f["name"] }.join(" // ")
      mana_cost =
        "#{response_data["card_faces"].first["mana_cost"]} / #{response_data["card_faces"].last["mana_cost"]}"
      card_image_urls = faces.map { |f| f.dig("image_uris", "large") }
      card_art_urls = faces.map { |f| f.dig("image_uris", "art_crop") }
      card_type = parse_card_type(type_line: faces.first["type_line"])
    end

    Models::Card.new(
      name: name,
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
      card_type: card_type,
      layout: parse_card_layout(card: response_data)
    )
  end

  def parse_card_type(type_line:)
    # if this is any type of creature (enchantment, artifact etc), return that type
    return :creature if type_line.match?(/creature/i)

    matcher =
      /(creature|artifact|battle|enchantment|instant|land|planeswalker|sorcery)/i

    return nil unless matcher.match?(type_line)

    matcher.match(type_line).captures.first.downcase.to_sym
  end

  def parse_card_layout(card:)
    dual_faced_card_layouts = %w[transform modal_dfc]
    flip_layouts = %w[flip]
    split_layouts = %w[split]

    if split_layouts.include?(card["layout"])
      if card["keywords"].map(&:downcase).include?("aftermath")
        return "aftermath"
      end
      "split"
    elsif flip_layouts.include?(card["layout"])
      "flip"
    elsif dual_faced_card_layouts.include?(card["layout"])
      return "battle" if card["type_line"].match?(/battle/i)
      "dual"
    else
      "normal"
    end
  end
end
