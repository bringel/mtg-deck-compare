# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  class ArchidektParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?archidekt\.com/(?:api/)?decks/(\d+)}

    def self.source_type
      :archidekt
    end

    def self.fetcher_options
      { rate_limit: { requests: 20, period: 1, unit: :minutes } }
    end

    def parse
      # the trailing slash at the end of this URL is *very* important
      # otherwise the request will not be routed to the right place
      # for some reason
      data =
        fetcher.get(
          "https://archidekt.com/api/decks/#{deck_id}/",
          accept: :json
        ).json

      in_deck_categories =
        data["categories"].filter_map do |cat|
          cat["name"] if cat["includedInDeck"]
        end

      sideboard_cards, main_deck_cards =
        data["cards"]
          .filter do |card|
            card["categories"].any? { |cat| in_deck_categories.include?(cat) }
          end
          .partition { |card| card["categories"].include?("Sideboard") }

      Models::ParsedDeck.new(
        name: data["name"],
        author: data.dig("owner", "username"),
        main_deck: main_deck_cards.map { |c| card_to_hash(card_data: c) },
        sideboard: sideboard_cards.map { |c| card_to_hash(card_data: c) }
      )
    end

    private

    def deck_id
      URL_PATTERN.match(url).captures.first
    end

    def card_to_hash(card_data:)
      set_code = card_data.dig("card", "edition", "editioncode")
      number = card_data.dig("card", "collectorNumber")

      if set_code.nil? || number.nil?
        return(
          {
            name: card_data.dig("card", "oracleCard", "name"),
            quantity: card_data["quantity"]
          }
        )
      end

      {
        set_code: set_code,
        set_number: number.to_i,
        quantity: card_data["quantity"]
      }
    end
  end
end
