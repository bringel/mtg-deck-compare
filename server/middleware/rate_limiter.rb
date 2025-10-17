# frozen_string_literal: true

require "redis"
require "uri"
require "securerandom"

module Middleware
  # Faraday middleware that rate limits requests per origin using Redis-based distributed locking
  #
  # Usage:
  #   conn = Faraday.new(url: "https://api.example.com") do |f|
  #     f.use Middleware::RateLimiter,
  #           redis: redis_instance,
  #           requests: 10,
  #           period: 1,
  #           unit: :minutes
  #     f.adapter Faraday.default_adapter
  #   end
  #
  # Options:
  #   - redis: Redis connection instance
  #   - requests: Number of requests allowed per period (default: 10)
  #   - period: Time period value (default: 1)
  #   - unit: Time unit - :seconds, :minutes, or :hours (default: :minutes)
  #   - key_prefix: Prefix for Redis keys (default: "rate_limit")
  #   - max_wait_time: Maximum time to wait for lock in seconds (default: 60)
  class RateLimiter < Faraday::Middleware
    UNITS = {
      seconds: 1,
      minutes: 60,
      hours: 3600
    }.freeze

    def initialize(app, options = {})
      super(app)
      @redis = options[:redis] or raise ArgumentError, "redis connection required"
      @requests = options.fetch(:requests, 10)
      @period = options.fetch(:period, 1)
      @unit = options.fetch(:unit, :minutes)
      @key_prefix = options.fetch(:key_prefix, "rate_limit")
      @max_wait_time = options.fetch(:max_wait_time, 60)

      validate_options!
    end

    def call(env)
      origin = extract_origin(env[:url])

      acquire_rate_limit_slot(origin) do
        @app.call(env)
      end
    end

    private

    def validate_options!
      raise ArgumentError, "unit must be one of: #{UNITS.keys.join(', ')}" unless UNITS.key?(@unit)
      raise ArgumentError, "requests must be positive" unless @requests > 0
      raise ArgumentError, "period must be positive" unless @period > 0
      raise ArgumentError, "max_wait_time must be positive" unless @max_wait_time > 0
    end

    def extract_origin(url)
      uri = url.is_a?(URI) ? url : URI.parse(url.to_s)
      "#{uri.scheme}://#{uri.host}:#{uri.port}"
    end

    def window_duration_seconds
      @period * UNITS[@unit]
    end

    def slot_duration_milliseconds
      (window_duration_seconds.to_f / @requests * 1000).round
    end

    # Acquires a rate limit slot for the given origin using Redis
    # Each request gets a lock that expires after (window_duration / requests) milliseconds
    # This ensures distributed rate limiting across multiple processes
    def acquire_rate_limit_slot(origin)
      lock_key = "#{@key_prefix}:#{origin}:lock"
      lock_value = SecureRandom.uuid
      duration_ms = slot_duration_milliseconds

      start_time = Time.now
      loop do
        # Try to acquire lock with auto-expiration
        lock_acquired = @redis.set(lock_key, lock_value, nx: true, px: duration_ms)

        if lock_acquired
          # Lock acquired, proceed with request
          return yield
        else
          # Lock is held by another request, wait with jitter to prevent thundering herd
          base_wait = slot_duration_milliseconds / 1000.0 / 10.0  # 10% of slot duration
          jitter = rand * base_wait  # Random jitter up to base_wait
          sleep(base_wait + jitter)
        end

        # Check if we've exceeded max wait time
        if Time.now - start_time > @max_wait_time
          raise Faraday::TimeoutError, "Rate limiter timeout after #{@max_wait_time}s waiting for slot to #{origin}"
        end
      end
    end
  end
end
