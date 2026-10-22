# frozen_string_literal: true

module Fetchers
  # Decides whether a response is a bot block / challenge rather than real content.
  #
  # Note that normal Cloudflare-fronted pages include a `/cdn-cgi/challenge-platform/`
  # script, so that string is *not* a reliable marker on its own
  module BlockDetector
    BODY_MARKERS = [
      "<title>Just a moment...</title>",
      "Attention Required! | Cloudflare",
      "cf_chl_opt",
      "cf-browser-verification"
    ].freeze

    def self.blocked?(response)
      return true if response.header("cf-mitigated") == "challenge"

      case response.status
      when 403, 429
        # 403 covers both Cloudflare WAF blocks and APIs refusing our user agent,
        # either way retrying from this IP won't help
        true
      when 503
        challenge_body?(response.body)
      else
        false
      end
    end

    def self.challenge_body?(body)
      return false if body.nil? || body.empty?

      BODY_MARKERS.any? { |marker| body.include?(marker) }
    end
  end
end
