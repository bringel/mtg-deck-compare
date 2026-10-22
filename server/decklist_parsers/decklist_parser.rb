# frozen_string_literal: true
require "json"
require "nokogiri"

require_relative "./errors"
require_relative "./text_list_parser"
require_relative "../fetchers/fetchers"
require_relative "../lib/service_registry"
require_relative "../models/parsed_deck"

module DecklistParsers
  # Base class for site-specific parsers.
  #
  # A parser knows how to turn one site's deck URL into a Models::ParsedDeck.
  # It does all of its network access through `fetcher`, so it never deals
  # with timeouts, retries, or blocks itself, and tests can hand it a fake
  # fetcher that serves fixture files. Caching and Scryfall lookups live in
  # DeckService.
  class DecklistParser
    attr_reader :url, :fetcher

    def self.can_handle_url?(url)
      url.match?(self::URL_PATTERN)
    end

    def self.source_type
      raise NotImplementedError
    end

    # Extra options for this source's HttpFetcher (headers, rate_limit, ...)
    def self.fetcher_options
      {}
    end

    def self.build_fetcher
      Fetchers.for(source_type, **fetcher_options)
    end

    def initialize(url, fetcher: nil, redis: nil)
      @url = url
      @fetcher = fetcher || self.class.build_fetcher
      @redis = redis
    end

    # Returns a Models::ParsedDeck
    def parse
      raise NotImplementedError
    end

    def source_type
      self.class.source_type
    end

    # A page the user can open in their own browser to copy the list from when
    # we can't fetch it from the server
    def fallback_url
      url
    end

    private

    def redis
      @redis || ServiceRegistry.redis
    end

    def html(response)
      Nokogiri.HTML(response.body)
    end

    def extraction_error(message)
      ExtractionError.new(
        message,
        source_type: source_type,
        fallback_url: fallback_url
      )
    end
  end
end
