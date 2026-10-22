# frozen_string_literal: true

require_relative "./http_fetcher"
require_relative "./scraping_api_fetcher"
require_relative "./tiered_fetcher"

module Fetchers
  # Builds the fetcher for a deck source.
  #
  # By default every source fetches directly. To route a source through a
  # scraping API when it blocks us, set both:
  #   SCRAPING_API_URL      - see ScrapingApiFetcher
  #   SCRAPING_API_SOURCES  - comma separated source types, e.g. "mtggoldfish,aetherhub"
  def self.for(source_type, **http_options)
    direct = HttpFetcher.new(source_type: source_type, **http_options)
    return direct unless scraping_api_enabled_for?(source_type)

    TieredFetcher.new(direct, ScrapingApiFetcher.new(source_type: source_type))
  end

  def self.scraping_api_enabled_for?(source_type)
    return false if ENV["SCRAPING_API_URL"].to_s.empty?

    ENV
      .fetch("SCRAPING_API_SOURCES", "")
      .split(",")
      .map(&:strip)
      .include?(source_type.to_s)
  end
end
