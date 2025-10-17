# frozen_string_literal: true
require_relative "../middleware/rate_limiter"
require_relative "../lib/service_registry"

module DecklistParsers
  class ArchidektParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?archidekt.com\/decks\/(\d+)/}

    def self.can_handle_url?(url)
      url.match?(URL_PATTERN)
    end

    def load_deck_info
    end

    def load_deck
      deck_id = URL_PATTERN.match(url).captures.first

      # the trailing slash at the end of this URL is *very* important
      # otherwise the request will not be routed to the right place
      # for some reason
      deck_data = api.get("/api/decks/#{deck_id}/")

      name = deck_data.body["name"]
      author = deck_data.body.dig("owner", "username")

      in_deck_categories =
        deck_data.body["categories"].filter_map do |cat|
          cat["name"] if cat["includedInDeck"]
        end

      sideboard_cards, main_deck_cards =
        deck_data.body["cards"]
          .filter do |card|
            card["categories"].any? { |cat| in_deck_categories.include?(cat) }
          end
          .partition { |card| card["categories"].include?("Sideboard") }

      main_deck =
        fetch_cards(
          card_hashes: main_deck_cards.map { |c| card_to_hash(card_data: c) }
        )
      sideboard =
        fetch_cards(
          card_hashes: sideboard_cards.map { |c| card_to_hash(card_data: c) }
        )

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :archidekt,
        source_url: url,
        main_deck: main_deck,
        sideboard: sideboard
      )
    end

    private

    def card_to_hash(card_data:)
      {
        set_code: card_data.dig("card", "edition", "editioncode"),
        set_number: card_data.dig("card", "collectorNumber").to_i,
        quantity: card_data["quantity"]
      }
    end

    def api
      @api ||=
        Faraday.new("https://archidekt.com") do |f|
          f.use Middleware::RateLimiter,
                redis: ServiceRegistry.redis,
                requests: 20,
                period: 1,
                unit: :minutes
          f.response :json
          f.adapter Faraday.default_adapter
        end
    end
  end
end
