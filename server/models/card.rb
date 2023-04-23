# frozen_string_literal: true

module Models
  Card =
    Struct.new(
      "Card",
      :card_id,
      :name,
      :set_code,
      :set_number,
      :mana_cost,
      :converted_mana_cost,
      :card_image_url,
      :card_art_url,
      :oracle_id,
      :multiverse_ids,
      :scryfall_url,
      keyword_init: true
    ) do
      def self.from_row(row)
        new(**row)
      end
    end
end
