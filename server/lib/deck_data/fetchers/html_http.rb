# frozen_string_literal: true
require "nokogiri"

module DeckData
  module Fetchers
    module HtmlHttp
      private

      def doc(url, params = {})
        Nokogiri.HTML(http_client.get(url, params).body)
      end
    end
  end
end
