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

    def load_deck
      user_id, deck_id = URL_PATTERN.match(url).captures

      response =
        Faraday.get("https://deckstats.net/decks/#{user_id}/#{deck_id}/en")
      doc = Nokogiri.HTML(response.body)

      deck_data = extract_deck_data(doc)

      set_mappings = fetch_set_mappings

      name = deck_data["name"]
      author = deck_data.dig("saved_by", "username") || "Unknown"

      user_href = "https://deckstats.net/decks/#{user_id}"

      user_link =
        doc
          .css("a[href^='#{user_href}']")
          .find { |anchor| anchor["href"].split("?").first == user_href }
      author = user_link&.text

      # Process sections - anything not "Sideboard" goes to main deck
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

      require "byebug"
      byebug
      main_deck = fetch_cards(card_hashes: main_deck_cards)
      sideboard = fetch_cards(card_hashes: sideboard_cards)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :deckstats,
        source_url: url,
        main_deck: main_deck,
        sideboard: sideboard
      )
    end

    private

    def extract_sets_version(doc)
      script_content = doc.css("script").map(&:content).join("\n")
      match = script_content.match(/sets_version\s*=\s*(\d+)/)
      match ? match[1] : ""
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
