# frozen_string_literal: true

module DeckData
  module Sources
    SourceDef =
      Data.define(:type, :url_pattern, :fetcher_class, :parser_class) do
        def can_handle_url?(url)
          url_pattern.match?(url)
        end
      end
  end
end
