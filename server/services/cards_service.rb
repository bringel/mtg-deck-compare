# frozen_string_literal: true

require_relative "./scryfall_service"
require_relative "../models/card"
require "json"

class CardsService
  def initialize
    @scryfall_service = ScryfallService.new
  end

  def get_card_from_set(set_code:, set_number:)
    # DB[:cards]
    #   .where(set_code: set_code, set_number: set_number)
    #   .read_through do |dataset|
    #     c =
    #       @scryfall_service.get_card_from_set(
    #         set_code: set_code,
    #         set_number: set_number
    #       )

    #     dataset.insert(
    #       c
    #         .to_h
    #         .except(:card_id)
    #         .merge(
    #           multiverse_ids: Sequel.pg_array(c["multiverse_ids"]),
    #           card_image_urls: Sequel.pg_array(c["card_image_urls"]),
    #           card_art_urls: Sequel.pg_array(c["card_art_urls"]),
    #           card_type: c["card_type"].to_s
    #         )
    #     )
    #   end
    #   .first
    key = "cards:#{set_code}:#{set_number}"
    if REDIS.exists?(key)
      return Models::Card.from_row(JSON.parse(REDIS.get(key)))
    else
      card =
        @scryfall_service.get_card_from_set(
          set_code: set_code,
          set_number: set_number
        )
      REDIS.set(key, JSON.dump(card.to_h))
      card
    end
  end

  def get_cards(card_hashes:)
    all_card_keys = REDIS.scan_each(match: "card:*").to_a

    existing_cards, missing_cards =
      card_hashes.partition do |c|
        all_card_keys.include?(
          card_key(set_code: c["set_code"], set_number: c["set_number"])
        )
      end

    existing_card_keys =
      existing_cards.map do |c|
        card_key(set_code: c["set_code"], set_number: c["set_number"])
      end

    existing_cards =
      if existing_cards.empty?
        []
      else
        REDIS
          .mget(*existing_card_keys)
          .map { |data| Models::Card.from_row(JSON.parse(data)) }
      end
    missing_cards = @scryfall_service.get_cards(card_hashes: missing_cards)

    missing_card_data =
      missing_cards.to_h do |card|
        data = card.to_h
        key = card_key(**data.slice(:set_code, :set_number))
        [key, JSON.generate(data)]
      end
    REDIS.mapped_mset(missing_card_data)
    existing_cards + missing_cards
  end

  def card_key(set_code:, set_number:)
    "cards:#{set_code}:#{set_number}"
  end
end
