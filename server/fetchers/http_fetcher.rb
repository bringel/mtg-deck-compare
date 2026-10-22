# frozen_string_literal: true
require "faraday"
require "faraday/follow_redirects"

require_relative "./response"
require_relative "./block_detector"
require_relative "../decklist_parsers/errors"
require_relative "../middleware/rate_limiter"
require_relative "../lib/service_registry"
require_relative "../lib/app_logger"

module Fetchers
  # Plain HTTP fetcher used for every deck source. Owns the network rules so the
  # parsers don't have to: timeouts, browser-like headers, retries for transient
  # failures, optional rate limiting, and turning bad responses into typed errors.
  class HttpFetcher
    USER_AGENT =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

    ACCEPT_HEADERS = {
      html:
        "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      json: "application/json",
      text: "text/plain,*/*;q=0.8"
    }.freeze

    RETRY_STATUSES = [429, 500, 502, 503, 504].freeze
    MAX_RETRY_AFTER_SECONDS = 5

    attr_reader :source_type

    def initialize(
      source_type:,
      headers: {},
      rate_limit: nil,
      open_timeout: 5,
      timeout: 20,
      max_retries: 2,
      redis: nil,
      adapter: nil,
      sleeper: Kernel.method(:sleep)
    )
      @source_type = source_type
      @headers = headers.compact
      @rate_limit = rate_limit
      @open_timeout = open_timeout
      @timeout = timeout
      @max_retries = max_retries
      @redis = redis
      @adapter = adapter
      @sleeper = sleeper
    end

    def get(url, params: {}, accept: :html, headers: {})
      attempts = 0

      loop do
        attempts += 1
        response =
          begin
            perform_get(url, params: params, accept: accept, headers: headers)
          rescue Middleware::RateLimiter::WaitTimeout => e
            raise unavailable_error(url, e)
          rescue Faraday::TimeoutError,
                 Faraday::ConnectionFailed,
                 Faraday::SSLError => e
            raise unavailable_error(url, e) if attempts > @max_retries

            @sleeper.call(backoff_seconds(attempts))
            next
          end

        if retryable?(response) && attempts <= @max_retries
          delay = retry_delay(response, attempts)
          if delay
            @sleeper.call(delay)
            next
          end
        end

        return check!(response)
      end
    end

    private

    def perform_get(url, params:, accept:, headers:)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      raw =
        connection.get(url, params) do |req|
          req.headers["Accept"] = ACCEPT_HEADERS.fetch(accept)
          headers.each { |k, v| req.headers[k] = v }
        end
      elapsed_ms =
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

      AppLogger.info(
        "fetch source=#{source_type} status=#{raw.status} ms=#{elapsed_ms} url=#{url}"
      )

      Response.new(
        status: raw.status,
        headers: raw.headers,
        body: utf8(raw.body),
        url: url
      )
    end

    def check!(response)
      if BlockDetector.blocked?(response)
        raise DecklistParsers::SourceBlockedError.new(
                "#{source_type} refused the request (HTTP #{response.status})",
                source_type: source_type
              )
      end

      return response if response.success?

      if [404, 410].include?(response.status)
        raise DecklistParsers::DeckNotFoundError.new(
                "#{source_type} says that deck doesn't exist (HTTP #{response.status})",
                source_type: source_type
              )
      end

      raise DecklistParsers::SourceUnavailableError.new(
              "#{source_type} returned HTTP #{response.status}",
              source_type: source_type
            )
    end

    def retryable?(response)
      return false unless RETRY_STATUSES.include?(response.status)
      return true if response.status == 429

      # a challenge page won't go away by asking again
      !BlockDetector.challenge_body?(response.body)
    end

    def retry_delay(response, attempts)
      retry_after = response.header("Retry-After")
      return backoff_seconds(attempts) unless retry_after

      seconds = Float(retry_after, exception: false)
      # an HTTP date, or a wait longer than we're willing to hold a request open
      return nil if seconds.nil? || seconds > MAX_RETRY_AFTER_SECONDS

      seconds
    end

    def backoff_seconds(attempts)
      (0.5 * (2**(attempts - 1))) + (rand * 0.25)
    end

    def unavailable_error(url, exception)
      AppLogger.warn(
        "fetch source=#{source_type} failed url=#{url} error=#{exception.class}: #{exception.message}"
      )
      DecklistParsers::SourceUnavailableError.new(
        "Couldn't reach #{source_type} (#{exception.class.name.split("::").last})",
        source_type: source_type
      )
    end

    def utf8(body)
      body = body.to_s
      return body unless body.encoding == Encoding::BINARY

      body.dup.force_encoding(Encoding::UTF_8)
    end

    def connection
      @connection ||=
        Faraday.new(
          headers: {
            "User-Agent" => USER_AGENT,
            "Accept-Language" => "en-US,en;q=0.9"
          }.merge(@headers),
          request: {
            open_timeout: @open_timeout,
            timeout: @timeout
          }
        ) do |f|
          f.response :follow_redirects, limit: 3
          if @rate_limit
            f.use Middleware::RateLimiter,
                  redis: @redis || ServiceRegistry.redis,
                  max_wait_time: 15,
                  **@rate_limit
          end
          @adapter ? f.adapter(*@adapter) : f.adapter(Faraday.default_adapter)
        end
    end
  end
end
