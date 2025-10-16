# frozen_string_literal: true
require "json"
require_relative "../services/cards_service"

module DecklistParsers
  class DecklistParser
    attr_reader :url, :redis

    def initialize(url, redis:)
      @url = url
      @redis = redis
    end

    def self.can_handle_url?(url)
    end

    def get_deck
      if redis.exists?(deck_key)
        return Models::Deck.from_json(redis.get(deck_key))
      end
      deck = load_deck
      redis.set(deck_key, JSON.generate(deck.to_h), ex: (5 * 60))
      deck
    end

    def load_deck_info
    end

    def load_deck
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
      card_hashes.each do |card_hash|
        key = card_hash.except(:quantity)
        card = cards[key]
        # Allow subclasses to provide custom lookup logic if direct lookup fails
        card = lookup_card_fallback(cards, card_hash) if card.nil?
        quantities[card.name] += card_hash[:quantity]
      end

      { quantities:, cards: cards.values.uniq { |c| c.name } }
    end

    # Override in subclasses if you need custom card lookup logic
    # (e.g., fallback to name-based search)
    def lookup_card_fallback(cards, card_hash)
      nil
    end

    def deck_key
      "decks:#{url}"
    end
  end
end
