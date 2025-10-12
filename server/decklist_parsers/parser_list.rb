# frozen_string_literal: true

require_relative "./aetherhub_parser.rb"
require_relative "./moxfield_parser"

module DecklistParsers
  class ParserList
    PARSERS = [AetherhubParser, MoxfieldParser]

    def self.get_parser(url)
      PARSERS.find { |parser| parser.can_handle_url?(url) }
    end
  end
end
