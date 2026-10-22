# frozen_string_literal: true
require "uri"

require_relative "../decklist_parsers/errors"

module DeckUrl
  MANUAL_DECK_PREFIX = "mtg-deck-compare://"

  # Normalizes a user-entered deck URL so the same deck always gets the same
  # cache key and parsers always get something fetchable:
  # adds a missing scheme, forces https, lowercases the host, and drops the
  # fragment and any trailing slash. The query string is kept since some sites
  # use it for access (e.g. Deckstats share keys).
  def self.normalize(url)
    str = url.to_s.strip
    return str if str.start_with?(MANUAL_DECK_PREFIX)

    str = "https://#{str}" unless str.match?(%r{\Ahttps?://}i)
    uri = URI.parse(str)
    raise URI::InvalidURIError, "missing host" if uri.host.to_s.empty?

    uri.scheme = "https"
    uri.host = uri.host.downcase
    uri.fragment = nil
    uri.path = uri.path.chomp("/") if uri.path.length > 1
    uri.to_s
  rescue URI::InvalidURIError
    raise DecklistParsers::UnsupportedUrlError, "#{url.inspect} isn't a valid URL"
  end

  def self.manual?(url)
    url.to_s.start_with?(MANUAL_DECK_PREFIX)
  end
end
