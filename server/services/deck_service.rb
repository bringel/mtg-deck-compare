# frozen_string_literal: true
require "json"
require "securerandom"

require_relative "../lib/service_registry"
require_relative "../lib/deck_url"
require_relative "../lib/app_logger"
require_relative "./cards_service"
require_relative "../models/card_key"
require_relative "../models/deck"
require_relative "../models/parsed_deck"
require_relative "../decklist_parsers/errors"
require_relative "../decklist_parsers/parser_list"
require_relative "../decklist_parsers/text_list_parser"

class DeckService
  # How long a deck is served from cache before we try to refetch it
  FRESH_TTL = 60 * 60
  # How long we keep the last good copy around to serve if a refetch fails
  STALE_TTL = 60 * 60 * 24 * 30
  MANUAL_DECK_TTL = 60 * 60 * 24 * 30

  MANUAL_DECK_PATTERN = %r{\Amtg-deck-compare://manualDeck/(.+)\z}

  attr_reader :redis

  def initialize(redis: ServiceRegistry.redis, cards_service: nil)
    @redis = redis
    @cards_service = cards_service
  end

  # Loads a deck from any supported URL (or a manual deck URL), using the
  # cache when possible. Raises a DecklistParsers::Error subclass on failure.
  def load_from_url(url)
    url = DeckUrl.normalize(url)

    if (manual_id = url[MANUAL_DECK_PATTERN, 1])
      return load_manual_deck(manual_id)
    end

    parser_class = DecklistParsers::ParserList.get_parser!(url)

    cached = redis.get(fresh_key(url))
    return Models::Deck.from_json(cached) if cached

    parser = parser_class.new(url, redis: redis)
    parsed =
      begin
        parse_with(parser)
      rescue DecklistParsers::DeckNotFoundError
        raise
      rescue DecklistParsers::Error => e
        stale = redis.get(stale_key(url))
        raise unless stale

        AppLogger.warn(
          "serving stale deck for #{url} after #{e.class}: #{e.message}"
        )
        return Models::Deck.from_json(stale)
      end

    save_parsed_deck(parsed, source_type: parser.source_type, source_url: url)
  end

  def deck_exists?(deck_key)
    redis.exists?(deck_key)
  end

  def load_deck(deck_key)
    Models::Deck.from_json(redis.get(deck_key))
  end

  def load_manual_deck(deck_id)
    data = redis.get(manual_deck_key(deck_id))
    unless data
      raise DecklistParsers::DeckNotFoundError.new(
              "That manually entered deck has expired or doesn't exist",
              source_type: :manual
            )
    end

    Models::Deck.from_json(data)
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
      build_deck(
        name: name,
        author: author,
        source_type: source_type,
        source_url: source_url,
        card_hashes: card_hashes
      )
    redis.set(deck_key, JSON.generate(deck.to_h), ex: ttl)

    deck
  end

  def save_manual_deck(name:, author:, url: nil, list:)
    parsed =
      Models::ParsedDeck.from_sections(
        name: name,
        author: author,
        sections: DecklistParsers::TextListParser.parse_decklist(list)
      )

    deck_id = SecureRandom.uuid
    deck =
      save_deck(
        name: name,
        author: author,
        source_type: :manual,
        source_url: url,
        card_hashes: {
          main_deck: parsed.main_deck,
          sideboard: parsed.sideboard
        },
        ttl: MANUAL_DECK_TTL,
        deck_key: manual_deck_key(deck_id)
      )

    { deck_id: deck_id, deck: deck }
  end

  private

  # Runs the parser, making sure anything it raises comes out as a
  # DecklistParsers::Error that knows its source and fallback URL
  def parse_with(parser)
    parsed = parser.parse
    if parsed.empty?
      raise DecklistParsers::ExtractionError, "The deck came back with no cards"
    end

    parsed
  rescue DecklistParsers::Error => e
    e.source_type ||= parser.source_type
    e.fallback_url ||= parser.fallback_url
    raise
  rescue StandardError => e
    # anything else (a nil from a missing element, bad JSON, ...) almost
    # always means the site changed its markup or sent us something unexpected
    AppLogger.error(
      "parser #{parser.class.name} failed for #{parser.url}: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    )
    raise DecklistParsers::ExtractionError.new(
            "We couldn't read the deck from #{parser.source_type}",
            source_type: parser.source_type,
            fallback_url: parser.fallback_url
          )
  end

  def save_parsed_deck(parsed, source_type:, source_url:)
    deck =
      build_deck(
        name: parsed.name,
        author: parsed.author,
        source_type: source_type,
        source_url: source_url,
        card_hashes: {
          main_deck: parsed.main_deck,
          sideboard: parsed.sideboard
        }
      )

    json = JSON.generate(deck.to_h)
    redis.set(fresh_key(source_url), json, ex: FRESH_TTL)
    redis.set(stale_key(source_url), json, ex: STALE_TTL)

    deck
  end

  def build_deck(name:, author:, source_type:, source_url:, card_hashes:)
    Models::Deck.new(
      name: name,
      author: author,
      source_type: source_type,
      source_url: source_url,
      main_deck: fetch_cards(card_hashes: card_hashes[:main_deck]),
      sideboard: fetch_cards(card_hashes: card_hashes[:sideboard])
    )
  end

  def cards_service
    @cards_service ||= CardsService.new(redis: redis)
  end

  def fetch_cards(card_hashes:)
    cards = cards_service.get_cards(card_hashes: card_hashes)

    quantities = Hash.new { 0 }
    full_card_keys = cards.keys
    card_hashes.each do |card_hash|
      key = Models::CardKey.from_card_hash(card_hash)
      full_key = full_card_keys.find { |full_key| full_key == key }
      card = cards[full_key]

      # one card Scryfall doesn't recognize shouldn't sink the whole deck
      unless card
        AppLogger.warn("no Scryfall match for #{card_hash.inspect}, skipping it")
        next
      end

      quantities[card.name] += card_hash[:quantity]
    end

    { quantities:, cards: cards.values.uniq { |c| c.name } }
  end

  def fresh_key(url)
    "decks:#{url}"
  end

  def stale_key(url)
    "decks:stale:#{url}"
  end

  def manual_deck_key(deck_id)
    "decks:manual:#{deck_id}"
  end
end
