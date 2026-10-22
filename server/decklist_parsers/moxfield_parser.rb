# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  class MoxfieldParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?moxfield\.com/decks/([^/?#]+)}

    def self.source_type
      :moxfield
    end

    # Moxfield hands out API access per user agent, and asks for at most 1 req/s
    def self.fetcher_options
      {
        headers: {
          "User-Agent" => ENV["MOXFIELD_USER_AGENT"]
        },
        rate_limit: {
          requests: 1,
          period: 1,
          unit: :seconds
        }
      }
    end

    def parse
      data =
        fetcher.get(
          "https://api.moxfield.com/v2/decks/all/#{deck_id}",
          accept: :json
        ).json

      Models::ParsedDeck.new(
        name: data["name"],
        author: author(data),
        main_deck: board(data["commanders"]) + board(data["mainboard"]),
        sideboard: board(data["companions"]) + board(data["sideboard"])
      )
    end

    private

    def deck_id
      URL_PATTERN.match(url).captures.first
    end

    def author(data)
      names = Array(data["authors"]).filter_map { |u| u["displayName"] }
      return names.join(", ") if names.any?

      data.dig("createdByUser", "displayName")
    end

    # boards are hashes of card name => { "quantity", "card" => {...} }
    def board(cards)
      (cards || {}).values.map { |c| card_to_hash(card_data: c) }
    end

    def card_to_hash(card_data:)
      card = card_data["card"] || {}
      if card["set"] == "plst"
        # cards from The List have collector numbers like "ELD-123"
        set, number = card["cn"].to_s.split("-")
      else
        set = card["set"]
        number = card["cn"]
      end

      if set.nil? || number.nil?
        return { name: card["name"], quantity: card_data["quantity"] }
      end

      {
        set_code: set.downcase,
        set_number: number.to_i,
        quantity: card_data["quantity"]
      }
    end
  end
end
