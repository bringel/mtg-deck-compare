# frozen_string_literal: true
require "faraday"
require "nokogiri"
require "json"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class MtgdecksParser < DecklistParser
    # Matches URLs like:
    # https://mtgdecks.net/Standard/deck-name-decklist-by-player-123456
    # https://mtgdecks.net/Modern/deck-name-decklist-by-player-123456
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtgdecks\.net/([^/]+)/(.+)-decklist-by-(.+)-(\d+)}

    def load_deck
      response = Faraday.get(url, {}, { "Accept" => "text/html" })
      doc = Nokogiri::HTML(response.body)

      name = extract_deck_name(doc)
      author = extract_author(doc)

      cards = extract_cards(doc)

      Models::Deck.new(
        name: name,
        author: author,
        source_type: :mtgdecks,
        source_url: url,
        main_deck: cards[:main_deck],
        sideboard: cards[:sideboard]
      )
    end

    private

    def extract_deck_name(doc)
      # Try multiple common selectors for deck name
      name =
        doc.css("h1.deck-title, h1.title, .deck-name, h1").first&.text&.strip

      # Clean up the name - remove player attribution if present
      name = name&.sub(/\s+by\s+.+$/i, "")&.strip if name

      # Fall back to extracting from page title
      if name.nil? || name.empty?
        title = doc.css("title").first&.text&.strip || ""
        name = title.split(" - ").first&.strip || "Unknown Deck"
        name = name.sub(/\s+by\s+.+$/i, "").strip
      end

      name || "Unknown Deck"
    end

    def extract_author(doc)
      # Try to extract from URL first
      url_match = URL_PATTERN.match(url)
      author_from_url = url_match.captures[2] if url_match

      # Try to find author in page
      author_elem =
        doc.css(".deck-author, .author, .player-name, [class*='author']").first
      author_from_page = author_elem&.text&.strip

      # Clean up author name (replace hyphens/underscores with spaces, capitalize)
      author =
        author_from_page || author_from_url || "Unknown"
      author
        .gsub(/[-_]/, " ")
        .split
        .map(&:capitalize)
        .join(" ")
    end

    def extract_cards(doc)
      # Try to find JSON data embedded in the page (common pattern)
      json_data = extract_json_data(doc)
      if json_data
        return parse_json_cards(json_data)
      end

      # Fall back to HTML parsing
      parse_html_cards(doc)
    end

    def extract_json_data(doc)
      # Look for JSON data in script tags
      script_tags = doc.css("script")
      script_tags.each do |script|
        content = script.content
        # Look for common patterns: window.DECK_DATA, var deckData, etc.
        if content.include?("deck") && content.include?("{")
          # Try to extract JSON objects
          json_matches = content.scan(/\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/)
          json_matches.each do |json_str|
            begin
              data = JSON.parse(json_str)
              # Check if this looks like deck data
              if data.is_a?(Hash) &&
                   (
                     data.key?("mainboard") || data.key?("main") ||
                       data.key?("cards")
                   )
                return data
              end
            rescue JSON::ParserError
              next
            end
          end
        end
      end
      nil
    end

    def parse_json_cards(data)
      # Handle different JSON structures
      main_deck_cards = []
      sideboard_cards = []

      # Try different common keys
      main_data = data["mainboard"] || data["main"] || data["cards"] || []
      side_data = data["sideboard"] || data["side"] || []

      main_data.each { |card| main_deck_cards << json_card_to_hash(card) }
      side_data.each { |card| sideboard_cards << json_card_to_hash(card) }

      {
        main_deck: fetch_cards(card_hashes: main_deck_cards),
        sideboard: fetch_cards(card_hashes: sideboard_cards)
      }
    end

    def json_card_to_hash(card_data)
      # Handle different JSON formats
      quantity =
        card_data["quantity"] || card_data["count"] || card_data["qty"] || 1
      name = card_data["name"] || card_data["card_name"]
      set_code = card_data["set"] || card_data["set_code"]
      collector_number =
        card_data["collector_number"] || card_data["number"] ||
          card_data["cn"]

      if set_code && collector_number
        {
          set_code: set_code.downcase,
          set_number: collector_number.to_i,
          quantity: quantity.to_i
        }
      else
        { name: name, quantity: quantity.to_i }
      end
    end

    def parse_html_cards(doc)
      main_deck_cards = []
      sideboard_cards = []

      # Look for card list containers
      card_sections =
        doc.css(
          ".decklist, .deck-list, .card-list, .deck-cards, [class*='deck']"
        )

      current_section = :main_deck

      # Parse card list text if found in a textarea or similar
      decklist_text =
        doc
          .css("textarea.deck-list, textarea[name*='deck'], pre.deck-list")
          .first
          &.text

      if decklist_text
        return parse_decklist_text(decklist_text)
      end

      # Parse HTML table or list structure
      card_rows =
        doc.css(
          "table.deck-list tr, .card-row, .deck-card, [class*='card-list'] > div"
        )

      card_rows.each do |row|
        # Check if this is a section header
        text = row.text.strip.downcase
        if text.include?("sideboard") || text.match?(/^sideboard/i)
          current_section = :sideboard
          next
        end

        # Extract quantity and card name
        quantity_elem = row.css(".qty, .quantity, td:first-child").first
        name_elem =
          row.css(".card-name, .name, td:nth-child(2), a").first

        next unless quantity_elem && name_elem

        quantity = quantity_elem.text.strip.to_i
        card_name = name_elem.text.strip

        next if quantity.zero? || card_name.empty?

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

    def parse_decklist_text(text)
      main_deck_cards = []
      sideboard_cards = []
      current_section = :main_deck

      text.each_line do |line|
        line = line.strip
        next if line.empty?

        # Check for section headers
        if line.downcase == "sideboard" ||
             line.downcase.start_with?("sideboard")
          current_section = :sideboard
          next
        end

        # Parse card line: "4 Lightning Bolt" or "4x Lightning Bolt"
        match = line.match(/^(\d+)x?\s+(.+)$/)
        next unless match

        quantity = match[1].to_i
        card_name = match[2].strip

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
