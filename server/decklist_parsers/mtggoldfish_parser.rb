# frozen_string_literal: true
require "faraday"
require "nokogiri"
require "byebug"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"
require_relative "./text_list_parser"

module DecklistParsers
  class MtggoldfishParser < DecklistParser
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    def deck_name
      name = doc.css(".deck-container h1.title").first&.text&.strip
      name.sub(/\s+by\s+.+$/i, "").strip
    end

    def author
      author_elem = doc.css(".deck-container span.author").first
      author_elem.text.sub(/\s*by\s*/i, "").strip
    end

    def card_hashes
      decklist_text = doc.css("input#deck_input_deck").first&.attr("value")

      unless decklist_text
        return { main_deck: [], sideboard: [] }
      end

      DecklistParsers::TextListParser.parse_decklist(decklist_text)
    end

    def source_type
      :mtggoldfish
    end

    private

    def doc
      if @doc
        @doc
      else
        response = Faraday.get(url, {}, { "Accept" => "text/html" })
        @doc = Nokogiri.HTML(response.body)
      end
    end
  end
end
