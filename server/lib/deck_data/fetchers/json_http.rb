# frozen_string_literal: true

module DeckData
  module Fetchers
    module JsonHttp
      private

      def get_json(url, params = {})
        http_client.get(url, params).body
      end
    end
  end
end
