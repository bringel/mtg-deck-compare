# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  class MtgDecksParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?mtgdecks\.net/\w+/(.+)}

    HEADER_PATTERN = /(?:MTG Arena)?(.*) deck, by(.*)/

    def self.source_type
      :mtg_decks
    end

    def parse
      doc = html(fetcher.get(url))

      decklist = doc.at_css("textarea#arena_deck")&.text
      raise extraction_error("Couldn't find the decklist on the page") unless decklist

      header = doc.css("h1:has(+ div#deck-tags-area)").text.strip
      match = header.match(HEADER_PATTERN)

      Models::ParsedDeck.from_sections(
        name: match ? match[1].strip : header,
        author: match&.[](2)&.strip,
        sections: TextListParser.parse_decklist(decklist)
      )
    end
  end
end
