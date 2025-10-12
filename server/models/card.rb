# frozen_string_literal: true
require "json"

module Models
  Card =
    Data.define(
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
      :layout
    ) do
      def dig(*keys)
        return unless keys.size.positive?

        k = keys.shift
        return unless respond_to?(k)

        value = public_send(k)
        return if value.nil?

        return value if keys.empty?
        unless value.respond_to?(:dig)
          raise ::TypeError, "#{value.class} does not have #dig method"
        end

        value.dig(*keys)
      end

      def self.from_row(row)
        new(**row.transform_keys(&:to_sym))
      end

      def to_json(opts)
        JSON.generate(self.to_h, opts)
      end

      def self.from_json(str)
        data = JSON.parse(str, { symbolize_names: true })
        new(**data.merge(card_type: data[:card_type].to_s))
      end
    end
end
