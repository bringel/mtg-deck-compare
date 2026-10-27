# frozen_string_literal: true

module DeckData
  class UnsupportedUrlError < StandardError
    def initialize(url)
      super("No deck source can handle #{url}")
    end
  end

  class ParseError < StandardError
  end

  class DeckNotFoundError < StandardError
    def initialize(deck_id)
      super("No saved deck found for #{deck_id}")
    end
  end
end
