# frozen_string_literal: true

require_relative "./fetcher"
require_relative "./json_http"
require_relative "../../../middleware/rate_limiter"
require_relative "../../service_registry"

module DeckData
  module Fetchers
    class ArchidektFetcher < Fetcher
      include JsonHttp

      attr_reader :id
      def initialize(url:, id:)
        super(url: url)
        @id = id
      end

      def deck_data
        # the trailing slash at the end of this URL is *very* important
        # otherwise the request will not be routed to the right place
        # for some reason
        @deck_data ||= get_json("https://archidekt.com/api/decks/#{id}/")
      end

      private

      def faraday_setup_block(f)
        super(f)
        f.use Middleware::RateLimiter,
              redis: ServiceRegistry.redis,
              requests: 20,
              period: 1,
              unit: :minutes
      end
    end
  end
end
