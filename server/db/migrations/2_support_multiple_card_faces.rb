# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:cards) do
      drop_column :card_image_url
      drop_column :card_art_url
      add_column :card_image_urls, "text[]"
      add_column :card_art_urls, "text[]"
    end
  end

  down do
    alter_table(:cards) do
      drop_column :card_image_urls
      drop_column :card_art_urls
      add_column :card_image_url, "text"
      add_column :card_art_url, "text"
    end
  end
end
