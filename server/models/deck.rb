# frozen_string_literal: true

module Models
  Deck =
    Struct.new(
      "Deck",
      :name,
      :source_type,
      :source_url,
      :main_deck,
      :sideboard,
      keyword_init: true
    ) do
      def to_json
        self.to_h.to_json
      end
    end
end
