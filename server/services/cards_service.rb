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
    return card_hashes.map { |h| get_card_from_set(**h) }
  end
end
