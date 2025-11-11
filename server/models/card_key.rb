# frozen_string_literal: true
require "json"

module Models
  CardKey =
    Data.define(:set_code, :card_number, :name) do
      def self.parse(str)
        _key, set, number, name = str.split(":")

        new(
          set_code: set.empty? ? nil : set,
          card_number: number.empty? ? nil : number.to_i,
          name: name.empty? ? nil : name
        )
      end

      def self.from_card_hash(hsh)
        new(
          set_code: hsh[:set_code],
          card_number: hsh[:set_number]&.to_i,
          name: hsh[:name]
        )
      end

      def self.from_json_response(str)
        data = str.is_a?(String) ? JSON.parse(str) : str
        # For cards with printed_name (like Spider-Man set), store both names
        # separated by "|||" so we can match against either in eql?
        name =
          if data["printed_name"]
            "#{data["name"]}|||#{data["printed_name"]}"
          else
            data["name"]
          end
        new(
          set_code: data["set"],
          card_number: data["collector_number"].to_i,
          name: name
        )
      end

      def self.from_card(card)
        new(
          set_code: card.set_code,
          card_number: card.set_number.to_i,
          name: card.name
        )
      end

      # Helper method to match card names, handling printed_name variants and split cards
      # For cards with printed_name (stored as "name|||printed_name"), match against either name
      # For split cards ("//"), only compares the first face to maintain original behavior
      def name_matches?(other)
        self_names = extract_names(name)
        other_names = extract_names(other.name)

        self_names.any? { |sn| other_names.any? { |on| sn == on } }
      end

      # Extract all possible name variants from a card name string
      # Handles printed_name variants ("|||") and takes first face of split cards ("//")
      def extract_names(name_str)
        # Split by printed_name delimiter, then take first face of any split cards
        name_str.split("|||").map { |n| n.split("//").first.strip }
      end

      # Overriding eql? and hash here to allow for matching against keys that only have a name instead of
      # a set and number. this is a sort of hacky way of handling cases where the information given from
      # a decklist doesn't have a set code or number, but we still want to check to see if we have a
      # version of the card in the cache. This _should_ allow for returning data from CardsService keyed by the
      # value that is passed in as the card_hash, instead of always being keyed by the data returned, and therefore
      # we can delete the lookup_card_fallback method since we will already have a matching key
      def eql?(other)
        return false if self.class != other.class

        unless set_code.nil? || card_number.nil? || other.set_code.nil? ||
                 other.card_number.nil?
          set_code == other.set_code && card_number == other.card_number
        else
          name_matches?(other)
        end
      end

      alias == eql?

      def hash
        unless set_code.nil? && card_number.nil?
          [self.class, set_code, card_number].hash
        else
          [self.class, name].hash
        end
      end

      def to_s
        "cards:#{set_code}:#{card_number}:#{name}"
      end
    end
end
