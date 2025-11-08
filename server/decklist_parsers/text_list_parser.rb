# frozen_string_literal: true

module DecklistParsers
  class TextListParser
    WITH_SET_AND_NUMBER = /^(\d+)\s+(.+)\s+\(([^)]+)\)\s+(\d+)$/

    QUANTITY_FIRST = /^(\d+)\s+(.+)$/

    QUANTITY_LAST = /^(.+)\s+(\d+)$/

    def self.parse_decklist(content)
      lines = content.split("\n").map(&:strip).reject(&:empty?)
      cards = { main_deck: [], sideboard: [], commander: [] }
      section = :main_deck

      lines.each do |line|
        if line.match?(/^commander:?/i)
          section = :commander
        elsif line.match?(/^sideboard:?/i)
          section = :sideboard
        elsif line.match?(/^(?:main )?deck:?/i)
          section = :main_deck
        end
        card = parse_line(line)
        cards[section] << card if card
      end

      cards
    end

    private

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
  end
end
