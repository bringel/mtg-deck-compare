# frozen_string_literal: true

require_relative "./aetherhub_parser.rb"
require_relative "./moxfield_parser"
require_relative "./archidekt_parser"
require_relative "./deckstats_parser"
require_relative "./mtggoldfish_parser"
require_relative "./mtgdecks_parser"
require_relative "./manual_deck_parser"

module DecklistParsers
  class ParserList
    PARSERS = [
      AetherhubParser,
      MoxfieldParser,
      ArchidektParser,
      DeckstatsParser,
      MtggoldfishParser,
      MtgDecksParser,
      ManualDeckParser
    ]

    def self.get_parser(url)
      PARSERS.find { |parser| parser.can_handle_url?(url) }
    end
  end
end
