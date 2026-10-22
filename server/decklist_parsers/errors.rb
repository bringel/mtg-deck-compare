# frozen_string_literal: true

module DecklistParsers
  # Base class for every expected failure while loading a deck from a URL.
  # Each subclass maps to an HTTP status and a stable `code` the frontend can
  # switch on, so the UI can say something more useful than "500".
  class Error < StandardError
    # writable so DeckService can fill these in for errors raised by fetchers,
    # which don't know which page the user should fall back to
    attr_accessor :source_type, :fallback_url

    # fallback_url is a page the *user* can open in their own browser to get
    # the list (e.g. a text export) when we can't fetch it from the server
    def initialize(message = nil, source_type: nil, fallback_url: nil)
      super(message)
      @source_type = source_type
      @fallback_url = fallback_url
    end

    def http_status
      500
    end

    def code
      "deck_load_failed"
    end

    def to_h
      {
        code: code,
        message: message,
        source_type: source_type,
        fallback_url: fallback_url
      }
    end
  end

  class UnsupportedUrlError < Error
    def http_status = 422
    def code = "unsupported_url"
  end

  class DeckNotFoundError < Error
    def http_status = 404
    def code = "deck_not_found"
  end

  # The site answered, but with a bot challenge, a WAF block, or a rate limit
  class SourceBlockedError < Error
    def http_status = 503
    def code = "source_blocked"
  end

  # Timeouts, connection failures, and 5xx responses
  class SourceUnavailableError < Error
    def http_status = 502
    def code = "source_unavailable"
  end

  # We got a normal-looking page back but couldn't find the deck in it,
  # which usually means the site changed its markup
  class ExtractionError < Error
    def http_status = 502
    def code = "extraction_failed"
  end
end
