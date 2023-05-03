# frozen_string_literal: true

require_relative "../db/read_through_db"
require_relative "./scryfall_service"

class CardsService
  def initialize
    @db = Data::ReadThroughDatabase.new(table_name: :cards)
    @scryfall_service = ScryfallService.new
  end

  def get_card_from_set(set_code:, set_number:)
    @db
      .where(set_code: set_code, set_number: set_number)
      .read_through do |dataset|
        c =
          @scryfall_service.get_card_from_set(
            set_code: set_code,
            set_number: set_number
          )

        dataset.insert(
          c
            .to_h
            .except(:card_id)
            .merge({ multiverse_ids: Sequel.pg_array(c["multiverse_ids"]) })
        )
      end
      .first
  end

  def get_cards(card_hashes:)
    return card_hashes.map { |h| get_card_from_set(**h) }
  end
end
