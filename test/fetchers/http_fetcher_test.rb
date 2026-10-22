# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/fetchers/http_fetcher"

class HttpFetcherTest < Minitest::Test
  URL = "https://decks.example.com/deck/1"

  CLOUDFLARE_BLOCK =
    "<html><head><title>Attention Required! | Cloudflare</title></head></html>"
  CLOUDFLARE_CHALLENGE =
    "<html><head><title>Just a moment...</title></head><script>window._cf_chl_opt={}</script></html>"

  def setup
    @sleeps = []
  end

  def fetcher_with(&stub_block)
    stubs = Faraday::Adapter::Test::Stubs.new(&stub_block)
    Fetchers::HttpFetcher.new(
      source_type: :example,
      adapter: [:test, stubs],
      sleeper: ->(seconds) { @sleeps << seconds }
    )
  end

  def test_returns_successful_responses
    fetcher = fetcher_with { |s| s.get(URL) { [200, {}, "deck!"] } }

    response = fetcher.get(URL)

    assert_equal 200, response.status
    assert_equal "deck!", response.body
    assert_equal Encoding::UTF_8, response.body.encoding
  end

  def test_sends_browser_like_headers
    seen = nil
    fetcher =
      fetcher_with do |s|
        s.get(URL) do |env|
          seen = env.request_headers
          [200, {}, ""]
        end
      end

    fetcher.get(URL, accept: :json)

    assert_match(/Mozilla/, seen["User-Agent"])
    assert_equal "application/json", seen["Accept"]
  end

  def test_cloudflare_block_raises_source_blocked_without_retrying
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          [403, { "server" => "cloudflare" }, CLOUDFLARE_BLOCK]
        end
      end

    error = assert_raises(DecklistParsers::SourceBlockedError) { fetcher.get(URL) }
    assert_equal :example, error.source_type
    assert_equal 1, calls
  end

  def test_challenge_served_as_503_is_blocked_and_not_retried
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          [503, {}, CLOUDFLARE_CHALLENGE]
        end
      end

    assert_raises(DecklistParsers::SourceBlockedError) { fetcher.get(URL) }
    assert_equal 1, calls
  end

  def test_cf_mitigated_header_is_a_block_even_on_200
    fetcher =
      fetcher_with do |s|
        s.get(URL) { [200, { "cf-mitigated" => "challenge" }, "<html></html>"] }
      end

    assert_raises(DecklistParsers::SourceBlockedError) { fetcher.get(URL) }
  end

  def test_404_raises_deck_not_found
    fetcher = fetcher_with { |s| s.get(URL) { [404, {}, "nope"] } }

    assert_raises(DecklistParsers::DeckNotFoundError) { fetcher.get(URL) }
  end

  def test_transient_5xx_is_retried
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          calls == 1 ? [502, {}, "bad gateway"] : [200, {}, "deck!"]
        end
      end

    assert_equal "deck!", fetcher.get(URL).body
    assert_equal 2, calls
    assert_equal 1, @sleeps.length
  end

  def test_persistent_5xx_raises_source_unavailable
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          [500, {}, "oops"]
        end
      end

    assert_raises(DecklistParsers::SourceUnavailableError) { fetcher.get(URL) }
    assert_equal 3, calls
  end

  def test_429_honors_a_short_retry_after
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          calls == 1 ? [429, { "Retry-After" => "2" }, ""] : [200, {}, "deck!"]
        end
      end

    assert_equal "deck!", fetcher.get(URL).body
    assert_equal [2.0], @sleeps
  end

  def test_429_with_a_long_retry_after_gives_up_immediately
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          [429, { "Retry-After" => "120" }, ""]
        end
      end

    assert_raises(DecklistParsers::SourceBlockedError) { fetcher.get(URL) }
    assert_equal 1, calls
  end

  def test_timeouts_are_retried_then_raise_source_unavailable
    calls = 0
    fetcher =
      fetcher_with do |s|
        s.get(URL) do
          calls += 1
          raise Faraday::TimeoutError
        end
      end

    assert_raises(DecklistParsers::SourceUnavailableError) { fetcher.get(URL) }
    assert_equal 3, calls
  end

  def test_follows_redirects
    fetcher =
      fetcher_with do |s|
        s.get(URL) { [301, { "Location" => "https://decks.example.com/deck/1/new" }, ""] }
        s.get("https://decks.example.com/deck/1/new") { [200, {}, "moved deck"] }
      end

    assert_equal "moved deck", fetcher.get(URL).body
  end
end
