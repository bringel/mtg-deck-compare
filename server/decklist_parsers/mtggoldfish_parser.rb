# frozen_string_literal: true
require "faraday"
require "nokogiri"
require "byebug"
require "capybara/dsl"
require "selenium/webdriver"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"
require_relative "./text_list_parser"

module DecklistParsers
  class MtggoldfishParser < DecklistParser
    include Capybara::DSL

    Capybara.register_driver :headless_chrome do |app|
      options =
        Selenium::WebDriver::Chrome::Options.new(
          args: %w[
            headless
            no-sandbox
            disable-gpu
            disable-dev-shm-usage
            verbose
          ]
        )

      Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
    end
    Capybara.default_driver = :headless_chrome
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    def initialize(url, redis: ServiceRegistry.redis)
      super(url, redis: redis)
      visit(url)
    end

    def deck_name
      name = first(".deck-container h1.title")&.text&.strip
      name.sub(/\s+by\s+.+$/i, "").strip
    end

    def author
      author_elem = first(".deck-container span.author")
      author_elem.text.sub(/\s*by\s*/i, "").strip
    end

    def card_hashes
      text_input = first(id: "deck_input_deck", visible: false)
      decklist_text = text_input.value

      return { main_deck: [], sideboard: [] } unless decklist_text

      DecklistParsers::TextListParser.parse_decklist(decklist_text)
    end

    def source_type
      :mtggoldfish
    end
  end
end
