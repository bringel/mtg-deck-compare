# frozen_string_literal: true
require "cgi"
require "uri"

require_relative "./http_fetcher"

module Fetchers
  # Fetches a page through a third-party scraping API (ScrapingBee, ZenRows,
  # ScraperAPI, ...). They all follow the same shape: GET their endpoint with an
  # API key and the target URL as query parameters, and get the target's body back.
  #
  # Configure with a URL template where `{url}` is replaced by the escaped target, e.g.
  #   SCRAPING_API_URL="https://app.scrapingbee.com/api/v1/?api_key=KEY&url={url}"
  #
  # Custom request headers (like Moxfield's user agent) are not forwarded; most
  # vendors need a vendor-specific parameter for that.
  class ScrapingApiFetcher
    PLACEHOLDER = "{url}"

    attr_reader :source_type

    def initialize(source_type:, url_template: ENV["SCRAPING_API_URL"], http: nil)
      unless url_template.to_s.include?(PLACEHOLDER)
        raise ArgumentError, "scraping API URL template must contain #{PLACEHOLDER}"
      end

      @source_type = source_type
      @url_template = url_template
      # rendering through a proxy pool is slow, so allow a much longer timeout
      @http =
        http ||
          HttpFetcher.new(source_type: source_type, timeout: 70, max_retries: 1)
    end

    def get(url, params: {}, accept: :html, headers: {})
      target = params.empty? ? url : append_query(url, params)
      api_url = @url_template.sub(PLACEHOLDER, CGI.escape(target))

      @http.get(api_url, accept: accept).with(url: url)
    end

    private

    def append_query(url, params)
      separator = url.include?("?") ? "&" : "?"
      "#{url}#{separator}#{URI.encode_www_form(params)}"
    end
  end
end
