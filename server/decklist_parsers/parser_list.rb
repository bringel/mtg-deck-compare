# frozen_string_literal: true

require_relative "./aetherhub_parser.rb"

module DecklistParsers
  class ParserList
    PARSERS = [
      AetherhubParser
    ]

    def self.get_parser(url)
      PARSERS.find do |parser|
        parser.can_handle_url?(url)
      end
    end
  end
end
