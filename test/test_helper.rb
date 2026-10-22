# frozen_string_literal: true
require "minitest/autorun"
require "json"

require_relative "../server/lib/app_logger"
require_relative "../server/lib/service_registry"
require_relative "../server/fetchers/response"
require_relative "../server/decklist_parsers/errors"

AppLogger.level = Logger::FATAL

# Just enough of the Redis API for the services under test
class FakeRedis
  attr_reader :store, :ttls

  def initialize
    @store = {}
    @ttls = {}
  end

  def get(key)
    @store[key]
  end

  def set(key, value, ex: nil)
    @store[key] = value
    @ttls[key] = ex
    "OK"
  end

  def exists?(key)
    @store.key?(key)
  end

  def mget(*keys)
    keys.map { |k| @store[k] }
  end

  def mapped_mset(hash)
    @store.merge!(hash)
  end

  def scan_each(match:)
    pattern = Regexp.new("\\A#{Regexp.escape(match).gsub("\\*", ".*")}\\z")
    @store.keys.select { |k| k.match?(pattern) }.each
  end
end

ServiceRegistry.register(:redis, FakeRedis.new)

# Serves canned responses by URL instead of touching the network.
# Values can be a Fetchers::Response or an exception to raise.
class FakeFetcher
  attr_reader :requests

  def initialize(routes = {})
    @routes = routes
    @requests = []
  end

  def source_type
    :fake
  end

  def get(url, params: {}, accept: :html, headers: {})
    @requests << { url: url, params: params, accept: accept }
    result = @routes.fetch(url) { raise "FakeFetcher has no route for #{url}" }
    raise result if result.is_a?(Exception)

    result
  end
end

module FixtureHelpers
  FIXTURES_DIR = File.expand_path("fixtures", __dir__)

  def fixture(path)
    File.read(File.join(FIXTURES_DIR, path))
  end

  def ok_response(body, url: "https://example.com", headers: {})
    Fetchers::Response.new(status: 200, headers: headers, body: body, url: url)
  end
end
