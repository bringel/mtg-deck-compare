# frozen_string_literal: true
require "json"
require "byebug"

require_relative "../lib/service_registry"
require_relative "./cards_service"
require_relative "../models/card_key"
require_relative "../models/deck"

class DeckService
  attr_reader :redis

  def initialize(redis: ServiceRegistry.redis)
    @redis = redis
  end

  def deck_exists?(deck_key)
    redis.exists?(deck_key)
  end

  def load_deck(deck_key)
    Models::Deck.from_json(redis.get(deck_key))
  end

  def load_manual_deck(deck_id)
    deck_key = manual_deck_key(deck_id)

    load_deck(deck_key)
  end

  def save_deck(
    name:,
    author:,
    source_type:,
    source_url:,
    card_hashes:,
    ttl:,
    deck_key:
  )
    deck =
      Models::Deck.new(
        name: name,
        author: author,
        source_type: source_type,
        source_url: source_url,
        main_deck: fetch_cards(card_hashes: card_hashes[:main_deck]),
        sideboard: fetch_cards(card_hashes: card_hashes[:sideboard])
      )
    redis.set(deck_key, JSON.generate(deck.to_h), ex: ttl)

    deck
  end

  def save_manual_deck(name:, author:, url: nil, list:)
    parsed_list = DecklistParsers::TextListParser.parse_decklist(list)

    deck_id = SecureRandom.uuid
    deck_key = manual_deck_key(deck_id)

    deck =
      save_deck(
        name: name,
        author: author,
        source_type: :manual,
        source_url: url,
        card_hashes: parsed_list,
        ttl: (60 * 60 * 24 * 30),
        deck_key: deck_key
      )

    { deck_id: deck_id, deck: deck }
  end

  private

  def fetch_cards(card_hashes:)
    cards_service = CardsService.new(redis: redis)
    cards = cards_service.get_cards(card_hashes: card_hashes)

    quantities = Hash.new { 0 }
    full_card_keys = cards.keys
    card_hashes.each do |card_hash|
      key = Models::CardKey.from_card_hash(card_hash)
      full_key = full_card_keys.find { |full_key| full_key == key }
      card = cards[full_key]
      quantities[card.name] += card_hash[:quantity]
    end

    { quantities:, cards: cards.values.uniq { |c| c.name } }
  end

  def manual_deck_key(deck_id)
    "decks:manual:#{deck_id}"
  end
end
