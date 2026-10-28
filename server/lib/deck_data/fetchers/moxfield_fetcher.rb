# frozen_string_literal: true

require_relative "./fetcher"
require_relative "./json_http"
require_relative "../../../middleware/rate_limiter"
require_relative "../../service_registry"

module DeckData
  module Fetchers
    class MoxfieldFetcher < Fetcher
      include JsonHttp

      attr_reader :id
      def initialize(url:, id:)
        super(url: url)
        @id = id
      end

      def deck_data
        @deck_data ||= get_json("https://api.moxfield.com/v2/decks/all/#{id}")
      end

      private

      def http_options
        super().merge(
          { headers: { "user-agent" => ENV["MOXFIELD_USER_AGENT"] } }
        )
      end

      def faraday_setup_block(f)
        super(f)
        f.use Middleware::RateLimiter,
              redis: ServiceRegistry.redis,
              requests: 1,
              period: 1,
              unit: :seconds
      end
    end
  end
end
