# frozen_string_literal: true

require_relative "./aetherhub_parser.rb"

module DecklistParsers
  PARSER_MAP = {
    aetherhub: {
      can_handle?:
        Proc.new { |url| url.match?(%r{(?:https?://)?aetherhub\.com/Deck/.*}) },
      klass: AetherhubParser
    }
  }

  def self.get_parser(url)
    PARSER_MAP.values.each do |parser|
      return parser[:klass] if parser[:can_handle?].call(url)
    end
  end
end
