# frozen_string_literal: true

module DeckData
  class UnsupportedUrlError < StandardError
    def initialize(url)
      super("No deck source can handle #{url}")
    end
  end
end
