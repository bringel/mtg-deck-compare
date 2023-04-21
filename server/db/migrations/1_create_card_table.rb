# frozen_string_literal: true

Sequel.migration do
  up do
    create_table(:cards) do
      column :card_id,
             :uuid,
             {
               primary_key: true,
               null: false,
               default: Sequel.function(:uuid_generate_v4)
             }
      column :name, :text, { null: false }
      column :set_code, :text, { null: false }
      column :set_number, :integer, { null: false }
      column :mana_cost, :text
      column :converted_mana_cost, :integer
      column :card_image_url, :text
      column :card_art_url, :text
      column :oracle_id, :uuid
      column :multiverse_ids, "integer[]"
      column :scryfall_url, :text

      index %i[set_code set_number]
    end
  end

  down { drop_table(:cards) }
end
