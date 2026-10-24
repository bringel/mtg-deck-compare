# frozen_string_literal: true
require "faraday"

module DeckData
  module Fetchers
    class HttpFetcher
      attr_reader :url

      def initialize(url:)
        @url = url
      end

      def http_options
        { url: url }
      end

      def faraday_setup_block(f)
        f.response :json
      end

      def http_client
        @http_client ||=
          Faraday.new(http_options, &method(:faraday_setup_block))
      end
    end
  end
end
