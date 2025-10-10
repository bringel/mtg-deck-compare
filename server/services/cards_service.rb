# frozen_string_literal: true

require_relative "./scryfall_service"
require_relative "../models/card"
require "json"

class CardsService
  attr_reader :scryfall_service, :redis

  def initialize(redis: nil)
    @scryfall_service = ScryfallService.new
    @redis = redis
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
    if redis.exists?(key)
      return Models::Card.from_row(JSON.parse(redis.get(key)))
    else
      card =
        @scryfall_service.get_card_from_set(
          set_code: set_code,
          set_number: set_number
        )
      redis.set(key, JSON.dump(card.to_h))
      card
    end
  end

  def get_cards(card_hashes:)
    all_card_keys = redis.scan_each(match: "cards:*").to_a

    existing_card_hashes, missing_card_hashes =
      card_hashes.partition do |c|
        all_card_keys.include?(card_key(card_hash: c))
      end

    existing_card_keys = existing_card_hashes.map { |c| card_key(card_hash: c) }

    existing_cards =
      if existing_card_hashes.empty?
        {}
      else
        index_cards_by_set_code_number(
          cards:
            redis
              .mget(*existing_card_keys)
              .map { |data| Models::Card.from_row(JSON.parse(data)) }
        )
      end
    missing_cards =
      @scryfall_service.get_cards(card_hashes: missing_card_hashes)

    unless missing_cards.empty?
      missing_card_data =
        missing_cards.to_h do |k, card|
          data = card.to_h
          key = card_key(card_hash: k)
          [key, JSON.generate(data)]
        end
      redis.mapped_mset(missing_card_data)
    end
    existing_cards.merge(missing_cards)
  end

  def card_key(card_hash:)
    return nil if card_hash.has_key?(:name)

    set_code, set_number =
      card_hash.transform_keys(&:to_sym).values_at(:set_code, :set_number)
    "cards:#{set_code.downcase}:#{set_number.to_i}"
  end

  def index_cards_by_set_code_number(cards:)
    cards.to_h do |card|
      [
        { set_code: card.set_code.downcase, set_number: card.set_number.to_i },
        card
      ]
    end
  end
end
