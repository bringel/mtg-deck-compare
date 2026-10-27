# frozen_string_literal: true
require "json"

require_relative "./fetcher"
require_relative "./html_http"
require_relative "./json_http"
require_relative "../../service_registry"

module DeckData
  module Fetchers
    class DeckstatsFetcher < Fetcher
      include HtmlHttp
      include JsonHttp

      SET_MAPPINGS_KEY = "deckstats:set_mappings"

      attr_reader :user_id, :deck_id
      def initialize(url:, user_id:, deck_id:)
        super(url: url)
        @user_id = user_id
        @deck_id = deck_id
      end

      def deck_data
        @deck_data ||= {
          page: doc("https://deckstats.net/decks/#{user_id}/#{deck_id}/en"),
          set_mappings: set_mappings,
          user_id: user_id
        }
      end

      private

      def set_mappings
        redis = ServiceRegistry.redis
        if redis.exists?(SET_MAPPINGS_KEY)
          return JSON.parse(redis.get(SET_MAPPINGS_KEY))
        end

        data =
          get_json(
            "https://deckstats.net/api.php",
            { cached: "", action: "get_sets2" }
          )
        sets = data["sets"] || {}

        # Build a mapping of set_id (as string) -> abbreviation (set code)
        mappings =
          sets.to_h do |set_id, set_info|
            code = set_info["wotc_abbreviation"] || set_info["abbreviation"]
            [set_id, code&.downcase]
          end

        redis.set(
          SET_MAPPINGS_KEY,
          JSON.generate(mappings),
          ex: (7 * 24 * 60 * 60)
        )

        mappings
      end
    end
  end
end
