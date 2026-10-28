# frozen_string_literal: true

require_relative "./fetcher"
require_relative "./html_http"

module DeckData
  module Fetchers
    class MtgDecksFetcher < Fetcher
      include HtmlHttp

      def deck_data
        @deck_data ||= doc(url)
      end
    end
  end
end
