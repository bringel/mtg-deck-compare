# frozen_string_literal: true

require_relative "./errors"
require_relative "./aetherhub_parser"
require_relative "./moxfield_parser"
require_relative "./archidekt_parser"
require_relative "./deckstats_parser"
require_relative "./mtggoldfish_parser"
require_relative "./mtgdecks_parser"

module DecklistParsers
  class ParserList
    PARSERS = [
      AetherhubParser,
      MoxfieldParser,
      ArchidektParser,
      DeckstatsParser,
      MtggoldfishParser,
      MtgDecksParser
    ].freeze

    def self.get_parser(url)
      PARSERS.find { |parser| parser.can_handle_url?(url) }
    end

    def self.get_parser!(url)
      get_parser(url) or
        raise UnsupportedUrlError, "We don't know how to load decks from #{url}"
    end
  end
end
