# frozen_string_literal: true

module DecklistParsers
  class TextListParser
    WITH_SET_AND_NUMBER = /^(\d+)\s+(.+)\s+\(([^)]+)\)\s+(\d+)$/

    QUANTITY_FIRST = /^(\d+)\s+(.+)$/

    QUANTITY_LAST = /^(.+)\s+(\d+)$/

    # Headers have to match the whole line so a card like "Commander's Plate 1"
    # isn't mistaken for the start of a section.
    # Allows an optional trailing colon and/or count, e.g. "Sideboard:" or "Deck (60)"
    SECTION_HEADERS = {
      /\Acommanders?\s*:?\s*(?:\(\d+\))?\z/i => :commander,
      /\A(?:sideboard|companion)\s*:?\s*(?:\(\d+\))?\z/i => :sideboard,
      /\A(?:main\s*)?(?:deck|board)\s*:?\s*(?:\(\d+\))?\z/i => :main_deck
    }.freeze

    # blank_line_starts_sideboard: some exports (like MTGGoldfish's text download)
    # have no section headers and just separate the sideboard with an empty line
    def self.parse_decklist(content, blank_line_starts_sideboard: false)
      lines = content.split("\n").map(&:strip)
      cards = { main_deck: [], sideboard: [], commander: [] }
      section = :main_deck

      lines.each do |line|
        if line.empty?
          if blank_line_starts_sideboard && section == :main_deck &&
               cards[:main_deck].any?
            section = :sideboard
          end
          next
        end

        header_section = section_for_header(line)
        if header_section
          section = header_section
          next
        end

        card = parse_line(line)
        cards[section] << card if card
      end

      cards
    end

    def self.section_for_header(line)
      SECTION_HEADERS.find { |pattern, _| line.match?(pattern) }&.last
    end

    def self.parse_line(line)
      # Try WITH_SET_AND_NUMBER first (most specific)
      if match = line.match(WITH_SET_AND_NUMBER)
        return(
          {
            quantity: match[1].to_i,
            name: match[2].strip,
            set_code: match[3],
            set_number: match[4]
          }
        )
      end

      if match = line.match(QUANTITY_FIRST)
        return { quantity: match[1].to_i, name: match[2].strip }
      end

      if match = line.match(QUANTITY_LAST)
        return { quantity: match[2].to_i, name: match[1].strip }
      end

      nil
    end

    private_class_method :section_for_header, :parse_line
  end
end
