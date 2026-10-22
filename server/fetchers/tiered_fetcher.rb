# frozen_string_literal: true

require_relative "../decklist_parsers/errors"
require_relative "../lib/app_logger"

module Fetchers
  # Tries each fetcher in order, moving on to the next only when the current one
  # is blocked. Used to try a direct request first and only pay for a scraping
  # API when the source actually refuses us.
  class TieredFetcher
    def initialize(*fetchers)
      raise ArgumentError, "at least one fetcher required" if fetchers.empty?

      @fetchers = fetchers
    end

    def source_type
      @fetchers.first.source_type
    end

    def get(url, **options)
      @fetchers.each_with_index do |fetcher, index|
        return fetcher.get(url, **options)
      rescue DecklistParsers::SourceBlockedError => e
        raise if index == @fetchers.length - 1

        AppLogger.info(
          "fetch source=#{source_type} blocked via #{fetcher.class.name}, falling back to #{@fetchers[index + 1].class.name}: #{e.message}"
        )
      end
    end
  end
end
