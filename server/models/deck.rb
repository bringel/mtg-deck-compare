# frozen_string_literal: true

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

      def to_json
        self.to_h.to_json
      end
    end
end
