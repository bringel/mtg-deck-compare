# frozen_string_literal: true
require_relative "../middleware/rate_limiter"
require_relative "../lib/service_registry"

module DecklistParsers
  class ArchidektParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?archidekt.com\/decks\/(\d+)/}

    def deck_name
      deck_data["name"]
    end

    def author
      deck_data.dig("owner", "username")
    end

    def card_hashes
      in_deck_categories =
        deck_data["categories"].filter_map do |cat|
          cat["name"] if cat["includedInDeck"]
        end

      sideboard_cards, main_deck_cards =
        deck_data["cards"]
          .filter do |card|
            card["categories"].any? { |cat| in_deck_categories.include?(cat) }
          end
          .partition { |card| card["categories"].include?("Sideboard") }

      {
        main_deck: main_deck_cards.map { |c| card_to_hash(card_data: c) },
        sideboard: sideboard_cards.map { |c| card_to_hash(card_data: c) }
      }
    end

    def source_type
      :archidekt
    end

    private

    def deck_data
      if @deck_data
        @deck_data
      else
        deck_id = URL_PATTERN.match(url).captures.first

        # the trailing slash at the end of this URL is *very* important
        # otherwise the request will not be routed to the right place
        # for some reason
        response = api.get("/api/decks/#{deck_id}/")
        @deck_data = response.body
      end
    end

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
