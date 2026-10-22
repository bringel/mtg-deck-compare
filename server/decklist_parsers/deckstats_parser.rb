# frozen_string_literal: true

require_relative "./decklist_parser"
require_relative "../lib/app_logger"
require "uri"

module DecklistParsers
  class DeckstatsParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?deckstats\.net/decks/(\d+)/([^/?#]+)}

    SET_MAPPINGS_CACHE_KEY = "deckstats:set_mappings"

    def self.source_type
      :deckstats
    end

    def parse
      doc = html(fetcher.get(page_url))
      deck_data = extract_deck_data(doc)
      set_mappings = fetch_set_mappings

      main_deck_cards = []
      sideboard_cards = []

      Array(deck_data["sections"]).each do |section|
        cards =
          Array(section["cards"]).map do |c|
            card_to_hash(card_data: c, set_mappings: set_mappings)
          end

        if section["name"] == "Sideboard"
          sideboard_cards.concat(cards)
        else
          main_deck_cards.concat(cards)
        end
      end

      Models::ParsedDeck.new(
        name: deck_data["name"],
        author: author(doc, deck_data),
        main_deck: main_deck_cards,
        sideboard: sideboard_cards
      )
    end

    private

    def page_url
      user_id, deck_slug = URL_PATTERN.match(url).captures
      query = URI.parse(url).query
      "https://deckstats.net/decks/#{user_id}/#{deck_slug}/en#{query ? "?#{query}" : ""}"
    end

    def author(doc, deck_data)
      user_id = URL_PATTERN.match(url).captures.first
      user_href = "https://deckstats.net/decks/#{user_id}"

      user_link =
        doc
          .css("a[href^='#{user_href}']")
          .find { |anchor| anchor["href"].split("?").first == user_href }

      user_link&.text || deck_data.dig("saved_by", "username") || "Unknown"
    end

    def extract_deck_data(doc)
      script =
        doc.css("script").find { |s| s.content.include?("init_deck_data") }
      json_match =
        script&.content&.match(/init_deck_data\(({.*?}), false\);/m)

      raise extraction_error("Couldn't find the deck data on the page") unless json_match

      JSON.parse(json_match[1])
    end

    # Deckstats uses its own set ids, so we need their set list to turn them
    # into real set codes. If we can't get it, every card falls back to a name
    # lookup instead of failing the whole deck
    def fetch_set_mappings
      cached = redis.get(SET_MAPPINGS_CACHE_KEY)
      return JSON.parse(cached) if cached

      data =
        fetcher.get(
          "https://deckstats.net/api.php",
          params: {
            cached: "",
            action: "get_sets2"
          },
          accept: :json
        ).json

      # Build a mapping of set_id (as string) -> abbreviation (set code)
      mappings =
        (data["sets"] || {}).to_h do |set_id, set_info|
          code = set_info["wotc_abbreviation"] || set_info["abbreviation"]
          [set_id, code&.downcase]
        end

      redis.set(
        SET_MAPPINGS_CACHE_KEY,
        JSON.generate(mappings),
        ex: (7 * 24 * 60 * 60)
      )

      mappings
    rescue DecklistParsers::Error, JSON::ParserError => e
      AppLogger.warn(
        "deckstats set mappings unavailable, falling back to card names: #{e.message}"
      )
      {}
    end

    def card_to_hash(card_data:, set_mappings:)
      # Try to use set_code + collector_number if available
      set_id =
        card_data["set_id"]&.to_s ||
          card_data.dig("data", "display_set_id")&.to_s
      collector_number =
        card_data["collector_number"] ||
          card_data.dig("data", "collector_number")

      if set_id && collector_number && set_mappings[set_id]
        {
          set_code: set_mappings[set_id],
          set_number: collector_number.to_i,
          quantity: card_data["amount"]
        }
      else
        { name: card_data["name"], quantity: card_data["amount"] }
      end
    end
  end
end
