# frozen_string_literal: true
require "faraday"

module DeckData
  module Fetchers
    class Fetcher
      attr_reader :url

      def initialize(url:)
        @url = url
      end

      def deck_data
        raise NotImplementedError
      end

      private

      def http_options
        {}
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
