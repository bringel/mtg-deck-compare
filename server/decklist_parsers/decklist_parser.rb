# frozen_string_literal: true

module DecklistParsers
  class DecklistParser
    def initialize(url)
      @url = url
    end

    def self.can_handle_url?(url)
    end

    def load_deck
    end

    private

    def get_card_info
    end
  end
end
