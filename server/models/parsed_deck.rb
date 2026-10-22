# frozen_string_literal: true

module Models
  # What every decklist parser returns: the deck's metadata plus card hashes
  # ({ quantity:, set_code:, set_number: } and/or { quantity:, name: }) that
  # haven't been looked up on Scryfall yet.
  #
  # Commanders are folded into the main deck, since that's how the comparison
  # treats them (and how Archidekt and Aetherhub already return them)
  ParsedDeck =
    Data.define(:name, :author, :main_deck, :sideboard) do
      def self.from_sections(name:, author:, sections:)
        new(
          name: name,
          author: author,
          main_deck:
            Array(sections[:commander]) + Array(sections[:main_deck]),
          sideboard: Array(sections[:sideboard])
        )
      end

      def initialize(name:, author:, main_deck:, sideboard: [])
        super(
          name: name,
          author: author,
          main_deck: clean(main_deck),
          sideboard: clean(sideboard)
        )
      end

      def empty?
        main_deck.empty? && sideboard.empty?
      end

      private

      def clean(card_hashes)
        Array(card_hashes).compact.select { |c| c[:quantity].to_i.positive? }
      end
    end
end
