# frozen_string_literal: true

module Models
  Deck = Data.define(
    :name,
    :source_type,
    :source_url,
    :main_deck,
    :sideboard
  ) do
    def to_json
      self.to_h.to_json
    end
  end
end
