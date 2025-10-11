# frozen_string_literal: true
require "json"

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
        return Models::Deck.from_row(JSON.parse(redis.get(deck_key)))
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

    def get_card_info
    end

    def deck_key
      "decks:#{url}"
    end
  end
end
