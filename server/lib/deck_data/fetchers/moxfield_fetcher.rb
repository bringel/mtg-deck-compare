# frozen_string_literal: true

require_relative "./http_fetcher"
require_relative "../../../middleware/rate_limiter"
require_relative "../../service_registry"

module DeckData
  module Fetchers
    class MoxfieldFetcher < HttpFetcher
      attr_reader :id
      def initialize(url:, id:)
        super(url: url)
        @id = id
      end

      def http_options
        super().merge(
          {
            headers: {
              "user-agent" => ENV["MOXFIELD_USER_AGENT"]
            },
            url: "https://api.moxfield.com"
          }
        )
      end

      # def faraday_setup_block(f)
      #   super(f)
      #   f.use Middleware::RateLimiter,
      #         redis: ServiceRegistry.redis,
      #         requests: 1,
      #         period: 1,
      #         unit: :seconds
      # end

      def deck_data
        if @deck_data
          @deck_data
        else
          response = http_client.get("v2/decks/all/#{id}")
          @deck_data = response.body
        end
      end
    end
  end
end
