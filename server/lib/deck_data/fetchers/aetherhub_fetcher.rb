# frozen_string_literal: true
require_relative "./fetcher"
require_relative "./html_http"
require_relative "./json_http"

module DeckData
  module Fetchers
    class AetherhubFetcher < Fetcher
      include HtmlHttp
      include JsonHttp

      def deck_data
        @deck_data ||=
          begin
            page = doc(url)
            deck_id = page.css("[data-deckid].mtgaExport").first["data-deckid"]
            deck_json =
              get_json(
                "https://aetherhub.com/Deck/FetchMtgaDeckJson",
                { deckId: deck_id, lang: 0, simple: false }
              )

            { page: page, deck_json: deck_json }
          end
      end
    end
  end
end
