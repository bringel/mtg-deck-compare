# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  # Everything we need is in the static HTML of both user deck and archetype
  # pages, so no browser is required:
  #   - `input#deck_input_deck` holds the list as text (with a "sideboard" line)
  #   - `.deck-container h1.title` holds the name, with the author in a nested span
  #
  # User deck URLs also contain the deck id, which lets us fall back to the
  # plain text export at /deck/download/<id> if the HTML page is blocked
  class MtggoldfishParser < DecklistParser
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    # also matches /deck/visual/1234567, /deck/download/1234567, etc.
    DECK_ID_PATTERN = %r{mtggoldfish\.com/deck/(?:[a-z_]+/)?(\d+)}

    def self.source_type
      :mtggoldfish
    end

    def parse
      response =
        begin
          fetcher.get(page_url)
        rescue SourceBlockedError
          raise unless deck_id

          return parse_download(fetcher.get(download_url, accept: :text))
        end

      parse_page(html(response))
    end

    def fallback_url
      deck_id ? download_url : url
    end

    private

    def deck_id
      url[DECK_ID_PATTERN, 1]
    end

    def page_url
      deck_id ? "https://www.mtggoldfish.com/deck/#{deck_id}" : url
    end

    def download_url
      "https://www.mtggoldfish.com/deck/download/#{deck_id}"
    end

    def parse_page(doc)
      decklist = doc.at_css("input#deck_input_deck")&.[]("value")
      raise extraction_error("Couldn't find the decklist on the page") unless decklist

      title = doc.at_css(".deck-container h1.title")
      # the title's own text is the deck name; the author is a nested span
      name = title&.xpath("text()")&.text.to_s.strip
      author =
        title&.at_css("span.author")&.text.to_s.sub(/\A\s*by\s*/i, "").strip

      Models::ParsedDeck.from_sections(
        name: name.empty? ? "MTGGoldfish deck" : name,
        author: author.empty? ? nil : author,
        sections: TextListParser.parse_decklist(decklist)
      )
    end

    # The text export has no author, but the deck name is in the file name:
    #   Content-Disposition: attachment; filename="Deck - Azorius Control.txt"
    def parse_download(response)
      filename =
        response.header("Content-Disposition").to_s[/filename="([^"]+)"/, 1]
      name = filename&.delete_suffix(".txt")&.delete_prefix("Deck - ")

      Models::ParsedDeck.from_sections(
        name: name || "MTGGoldfish deck #{deck_id}",
        author: nil,
        sections:
          TextListParser.parse_decklist(
            response.body,
            blank_line_starts_sideboard: true
          )
      )
    end
  end
end
