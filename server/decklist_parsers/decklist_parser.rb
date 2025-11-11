# frozen_string_literal: true
require "json"
require_relative "../services/cards_service"
require_relative "../lib/service_registry"
require_relative "../models/card_key"

module DecklistParsers
  class DecklistParser
    attr_reader :url, :redis

    def initialize(url, redis: ServiceRegistry.redis)
      @url = url
      @redis = redis
    end

    def self.can_handle_url?(url)
      url.match?(self::URL_PATTERN)
    end

    def get_deck
      if redis.exists?(deck_key)
        return Models::Deck.from_json(redis.get(deck_key))
      end
      deck = load_deck
      redis.set(deck_key, JSON.generate(deck.to_h), ex: (5 * 60))
      deck
    end

    def load_deck
      Models::Deck.new(
        name: deck_name,
        author: author,
        source_type: source_type,
        source_url: url,
        main_deck: fetch_cards(card_hashes: card_hashes[:main_deck]),
        sideboard: fetch_cards(card_hashes: card_hashes[:sideboard])
      )
    end

    def deck_name
      raise NotImplementedError
    end

    def author
      raise NotImplementedError
    end

    def card_hashes
      rase NotImplementedError
    end

    def source_type
      raise NotImplementedError
    end

    private

    # Fetches cards from CardsService and aggregates quantities by card name
    # Subclasses should call this method with an array of card hashes from card_to_hash
    #
    # @param card_hashes [Array<Hash>] Array of hashes with format:
    #   { set_code: String, set_number: Integer, quantity: Integer } or
    #   { name: String, quantity: Integer }
    # @return [Hash] { quantities: Hash<String, Integer>, cards: Array<Card> }
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

    def deck_key
      "decks:#{url}"
    end
  end
end
