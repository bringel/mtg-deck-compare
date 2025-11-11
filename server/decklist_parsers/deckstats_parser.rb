# frozen_string_literal: true
require "faraday"
require "nokogiri"
require "json"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class DeckstatsParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?deckstats\.net/decks/(\d+)/(.+)}

    def deck_name
      deck_data["name"]
    end

    def author
      author_from_data = deck_data.dig("saved_by", "username")
      author_from_link = user_link&.text
      author_from_link || author_from_data || "Unknown"
    end

    def card_hashes
      set_mappings = fetch_set_mappings

      main_deck_cards = []
      sideboard_cards = []

      deck_data["sections"]&.each do |section|
        cards =
          section["cards"].map do |c|
            card_to_hash(card_data: c, set_mappings: set_mappings)
          end

        if section["name"] == "Sideboard"
          sideboard_cards.concat(cards)
        else
          main_deck_cards.concat(cards)
        end
      end

      { main_deck: main_deck_cards, sideboard: sideboard_cards }
    end

    def source_type
      :deckstats
    end

    private

    def doc
      if @doc
        @doc
      else
        user_id, deck_id = URL_PATTERN.match(url).captures
        response =
          Faraday.get("https://deckstats.net/decks/#{user_id}/#{deck_id}/en")
        @doc = Nokogiri.HTML(response.body)
      end
    end

    def deck_data
      @deck_data ||= extract_deck_data(doc)
    end

    def user_link
      user_id = URL_PATTERN.match(url).captures.first
      user_href = "https://deckstats.net/decks/#{user_id}"

      doc
        .css("a[href^='#{user_href}']")
        .find { |anchor| anchor["href"].split("?").first == user_href }
    end

    def extract_deck_data(doc)
      script_tags = doc.css("script")
      deck_data_json = nil
      script_tags.each do |script|
        if script.content.include?("init_deck_data")
          json_match =
            script.content.match(/init_deck_data\(({.*?}), false\);/m)
          deck_data_json = json_match[1] if json_match
          break
        end
      end

      raise "Could not find deck_data in page" unless deck_data_json
      JSON.parse(deck_data_json)
    end

    def fetch_set_mappings
      cache_key = "deckstats:set_mappings"

      return JSON.parse(redis.get(cache_key)) if redis.exists?(cache_key)

      response =
        Faraday.get(
          "https://deckstats.net/api.php",
          { cached: "", action: "get_sets2" }
        )

      data = JSON.parse(response.body)
      sets = data["sets"] || {}

      # Build a mapping of set_id (as string) -> abbreviation (set code)
      mappings = {}
      sets.each do |set_id, set_info|
        code = set_info["wotc_abbreviation"] || set_info["abbreviation"]
        mappings[set_id] = code&.downcase
      end

      redis.set(cache_key, JSON.generate(mappings), ex: (7 * 24 * 60 * 60))

      mappings
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
