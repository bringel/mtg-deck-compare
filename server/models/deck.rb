# frozen_string_literal: true
require "json"

module Models
  Deck =
    Data.define(:name, :source_type, :source_url, :main_deck, :sideboard) do
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

      def to_json(opts)
        JSON.generate(self.to_h, opts)
      end

      def self.from_row(row)
        new(**row.transform_keys(&:to_sym))
      end

      def self.from_json(str)
        data = JSON.parse(str, { symbolize_names: true })
        data =
          data.merge(
            {
              main_deck: deserialize_section(section: data[:main_deck]),
              sideboard: deserialize_section(section: data[:sideboard])
            }
          )
        new(**data)
      end

      def self.deserialize_section(section:)
        section.merge(
          {
            cards: section[:cards].map { |c| Models::Card.from_row(c) },
            quantities: section[:quantities].transform_keys(&:to_s)
          }
        )
      end
    end
end
