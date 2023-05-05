# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:cards) do
      add_column :rarity, :text
      add_column :card_type, :text
    end
  end
end
