# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class MtggoldfishParser < DecklistParser
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    def load_deck
      response = Faraday.get(url, {}, { "Accept" => "text/html" })
      doc = Nokogiri.HTML(response.body)

      name = extract_deck_name(doc)

      author = extract_author(doc)

      decklist_text = doc.css("input#deck_input_deck").first&.attr("value")

      cards = parse_decklist_text(decklist_text)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :mtggoldfish,
        source_url: url,
        main_deck: cards[:main_deck],
        sideboard: cards[:sideboard]
      )
    end

    private

    def extract_deck_name(doc)
      # Try h1.deck-view-title first (user decks)
      name = doc.css(".deck-container h1.title").first&.text&.strip

      # Fall back to page title
      if name.nil? || name.empty?
        title = doc.css("title").first&.text&.strip || ""
        # Remove " - MTGGoldfish" suffix and author prefix if present
        name = title.split(" - ").first&.strip || "Unknown Deck"
        # Remove "by [author]" suffix if present
        name = name.sub(/\s+by\s+.+$/i, "").strip
      end

      name
    end

    def extract_author(doc)
      # Try to find author link in deck-view-author
      author_elem = doc.css(".deck-container span.author").first
      return author_elem.text.strip if author_elem

      # Try to extract from title (format: "Deck Name by Author")
      title = doc.css("title").first&.text&.strip || ""
      match = title.match(/by\s+([^-]+)/i)
      return match[1].strip if match

      "Unknown"
    end

    def parse_decklist_text(text)
      unless text
        return(
          {
            main_deck: fetch_cards(card_hashes: []),
            sideboard: fetch_cards(card_hashes: [])
          }
        )
      end

      main_deck_cards = []
      sideboard_cards = []
      current_section = :main_deck

      text.each_line do |line|
        line = line.strip
        next if line.empty?

        if line.downcase == "sideboard" ||
             line.downcase.start_with?("sideboard")
          current_section = :sideboard
          next
        end

        match = line.match(/^(\d+)\s+(.+)$/)
        next unless match

        quantity = match[1].to_i
        card_name = match[2].strip

        # no set information on the goldfish pages so we have to fall back
        # to name based searches
        card_hash = { name: card_name, quantity: quantity }

        if current_section == :sideboard
          sideboard_cards << card_hash
        else
          main_deck_cards << card_hash
        end
      end

      {
        main_deck: fetch_cards(card_hashes: main_deck_cards),
        sideboard: fetch_cards(card_hashes: sideboard_cards)
      }
    end

    def lookup_card_fallback(cards, card_hash)
      if card_hash[:name]
        cards.values.find do |c|
          c.name.split(" // ").include?(card_hash[:name])
        end
      end
    end
  end
end
