# frozen_string_literal: true

module Models
  Card =
    Struct.new(
      "Card",
      :name,
      :set_code,
      :set_number,
      :mana_cost,
      :converted_mana_cost,
      :card_image_urls,
      :card_art_urls,
      :oracle_id,
      :multiverse_ids,
      :scryfall_url,
      :rarity,
      :card_type,
      keyword_init: true
    ) do
      def self.from_row(row)
        new(**row.merge(card_type: row["card_type"].to_s))
      end
    end
end
