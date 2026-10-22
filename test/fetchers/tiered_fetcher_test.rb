# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/fetchers/fetchers"

class TieredFetcherTest < Minitest::Test
  include FixtureHelpers

  URL = "https://decks.example.com/deck/1"

  def blocked
    DecklistParsers::SourceBlockedError.new("blocked")
  end

  def test_uses_the_first_fetcher_when_it_succeeds
    direct = FakeFetcher.new(URL => ok_response("direct"))
    fallback = FakeFetcher.new(URL => ok_response("fallback"))

    response = Fetchers::TieredFetcher.new(direct, fallback).get(URL)

    assert_equal "direct", response.body
    assert_empty fallback.requests
  end

  def test_falls_back_when_blocked
    direct = FakeFetcher.new(URL => blocked)
    fallback = FakeFetcher.new(URL => ok_response("fallback"))

    response = Fetchers::TieredFetcher.new(direct, fallback).get(URL)

    assert_equal "fallback", response.body
  end

  def test_does_not_fall_back_for_other_errors
    direct =
      FakeFetcher.new(URL => DecklistParsers::DeckNotFoundError.new("gone"))
    fallback = FakeFetcher.new(URL => ok_response("fallback"))

    assert_raises(DecklistParsers::DeckNotFoundError) do
      Fetchers::TieredFetcher.new(direct, fallback).get(URL)
    end
    assert_empty fallback.requests
  end

  def test_raises_when_every_fetcher_is_blocked
    fetcher =
      Fetchers::TieredFetcher.new(
        FakeFetcher.new(URL => blocked),
        FakeFetcher.new(URL => blocked)
      )

    assert_raises(DecklistParsers::SourceBlockedError) { fetcher.get(URL) }
  end

  def test_scraping_api_fetcher_wraps_the_target_url
    http = FakeFetcher.new
    def http.get(url, **)
      @requests << url
      Fetchers::Response.new(status: 200, headers: {}, body: "page", url: url)
    end

    fetcher =
      Fetchers::ScrapingApiFetcher.new(
        source_type: :example,
        url_template: "https://scraper.example.com/?key=abc&url={url}",
        http: http
      )
    response = fetcher.get(URL, params: { "a" => "1 2" })

    assert_equal [
                   "https://scraper.example.com/?key=abc&url=https%3A%2F%2Fdecks.example.com%2Fdeck%2F1%3Fa%3D1%2B2"
                 ],
                 http.requests
    assert_equal URL, response.url
  end

  def test_factory_only_adds_the_scraping_api_for_configured_sources
    with_env(
      "SCRAPING_API_URL" => "https://scraper.example.com/?url={url}",
      "SCRAPING_API_SOURCES" => "mtggoldfish, aetherhub"
    ) do
      assert_instance_of Fetchers::TieredFetcher, Fetchers.for(:mtggoldfish)
      assert_instance_of Fetchers::HttpFetcher, Fetchers.for(:archidekt)
    end

    with_env("SCRAPING_API_URL" => nil, "SCRAPING_API_SOURCES" => "mtggoldfish") do
      assert_instance_of Fetchers::HttpFetcher, Fetchers.for(:mtggoldfish)
    end
  end

  private

  def with_env(vars)
    previous = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    previous.each { |k, v| ENV[k] = v }
  end
end
