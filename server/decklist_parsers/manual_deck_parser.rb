# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  class ManualDeckParser < DecklistParser
    URL_PATTERN = %r{mtg-deck-compare://manualDeck/(.+)}

    def get_deck
      if deck_service.deck_exists?(deck_key)
        return deck_service.load_deck(deck_key)
      end

      # deck_service.save_deck(
      #   name: deck_name,
      #   author: author,
      #   source_type: source_type,
      #   source_url: url,
      #   card_hashes: card_hashes,
      #   ttl: (5 * 60),
      #   deck_key: deck_key
      # )
      raise ModelNotFoundError
    end

    def deck_name
      raise NotImplementedError
    end

    def author
      raise NotImplementedError
    end

    def card_hashes
      rase NotImplementedError
    end

    def source_type
      raise NotImplementedError
    end

    private

    def deck_key
      "decks:manual:#{id}"
    end

    def id
      matches = URL_PATTERN.match(url)

      matches.captures.first
    end
  end
end
