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
      if deck_service.deck_exists?(deck_key)
        return deck_service.load_deck(deck_key)
      end

      deck_service.save_deck(
        name: deck_name,
        author: author,
        source_type: source_type,
        source_url: url,
        card_hashes: card_hashes,
        ttl: (5 * 60),
        deck_key: deck_key
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

    def deck_service
      @deck_service ||= DeckService.new
    end

    def deck_key
      "decks:#{url}"
    end
  end
end
