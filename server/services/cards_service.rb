# frozen_string_literal: true

require_relative "./scryfall_service"
require_relative "../models/card"
require_relative "../models/card_key"
require_relative "../lib/service_registry"
require "json"

class CardsService
  attr_reader :scryfall_service, :redis

  def initialize(redis: ServiceRegistry.redis)
    @scryfall_service = ScryfallService.new
    @redis = redis
  end

  def get_card_from_set(set_code:, set_number:)
    key = "cards:#{set_code}:#{set_number}"
    if redis.exists?(key)
      return Models::Card.from_json(redis.get(key))
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
    all_card_keys =
      redis
        .scan_each(match: "cards:*")
        .to_a
        .map { |k| Models::CardKey.parse(k) }

    existing_card_keys = []
    missing_card_hashes = []
    card_hashes.each do |c|
      key =
        all_card_keys.find do |existing_key|
          existing_key == Models::CardKey.from_card_hash(c)
        end
      key ? existing_card_keys << key : missing_card_hashes << c
    end
    # existing_card_hashes, missing_card_hashes =
    #   card_hashes.partition do |c|
    #     all_card_keys.include?(Models::CardKey.from_card_hash(c))
    #   end

    # existing_card_keys = existing_card_hashes.map { |c| card_key(card_hash: c) }

    existing_cards =
      if existing_card_keys.empty?
        {}
      else
        cards =
          redis
            .mget(*existing_card_keys.map(&:to_s))
            .map { |data| Models::Card.from_json(data) }
        cards.to_h { |card| [Models::CardKey.from_card(card), card] }
      end
    missing_cards =
      @scryfall_service.get_cards(card_hashes: missing_card_hashes)

    unless missing_cards.empty?
      missing_card_data =
        missing_cards.to_h do |card_key, card|
          data = card.to_h
          key = card_key.to_s
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
end
