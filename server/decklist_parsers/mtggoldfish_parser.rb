# frozen_string_literal: true
require "faraday"
require "nokogiri"
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
      options = Selenium::WebDriver::Chrome::Options.new

      # Use new headless mode (less detectable than old headless)
      # options.add_argument("--headless=new")

      # Basic required flags
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")

      # Anti-detection flags
      options.add_argument("--disable-blink-features=AutomationControlled")
      options.add_argument("--disable-infobars")
      options.add_argument("--disable-extensions")

      # Realistic window size
      options.add_argument("--window-size=1732,925")

      # More anti-fingerprinting
      options.add_argument("--disable-features=IsolateOrigins,site-per-process")

      # Realistic user agent (updated to Chrome 131)
      options.add_argument(
        "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
      )

      # Disable automation flags that Cloudflare detects
      options.add_preference("credentials_enable_service", false)
      options.add_preference("profile.password_manager_enabled", false)

      # Additional preferences to appear more like a real browser
      options.add_preference(
        "profile.default_content_setting_values.notifications",
        2
      )
      options.add_preference(
        "profile.managed_default_content_settings.images",
        1
      )

      # Exclude automation switches
      options.exclude_switches << "enable-automation"
      options.exclude_switches << "enable-logging"

      client = Selenium::WebDriver::Remote::Http::Default.new
      client.read_timeout = 180

      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        http_client: client,
        options: options
      )
    end
    Capybara.default_driver = :headless_chrome
    # Matches both user decks and archetype decks
    # User deck: https://www.mtggoldfish.com/deck/1234567
    # Archetype: https://www.mtggoldfish.com/archetype/standard-dimir-midrange-woe
    URL_PATTERN =
      %r{(?:https?://)?(?:www\.)?mtggoldfish\.com/(?:deck|archetype)/[^#?]+}

    def initialize(url, redis: ServiceRegistry.redis)
      super(url, redis: redis)

      # Use CDP to remove webdriver flag and add stealth scripts
      driver = page.driver.browser
      driver.execute_cdp("Page.addScriptToEvaluateOnNewDocument", source: <<~JS)
          // Remove webdriver property
          Object.defineProperty(navigator, 'webdriver', { get: () => undefined });

          // Mock plugins array with realistic plugins
          Object.defineProperty(navigator, 'plugins', {
            get: () => [
              { name: 'Chrome PDF Plugin' },
              { name: 'Chrome PDF Viewer' },
              { name: 'Native Client' }
            ]
          });

          // Mock languages
          Object.defineProperty(navigator, 'languages', {
            get: () => ['en-US', 'en']
          });

          // Mock permissions
          const originalQuery = window.navigator.permissions.query;
          window.navigator.permissions.query = (parameters) => (
            parameters.name === 'notifications' ?
              Promise.resolve({ state: Notification.permission }) :
              originalQuery(parameters)
          );

          // Remove Chrome automation indicators
          window.chrome = {
            runtime: {},
            loadTimes: function() {},
            csi: function() {},
            app: {}
          };

          // Mock realistic screen properties
          Object.defineProperty(screen, 'availWidth', { get: () => 1920 });
          Object.defineProperty(screen, 'availHeight', { get: () => 1040 });
          Object.defineProperty(screen, 'colorDepth', { get: () => 24 });

          // Override navigator.platform
          Object.defineProperty(navigator, 'platform', { get: () => 'Win32' });
        JS

      # Add random delay before visiting (mimic human behavior)
      sleep(rand(1.0..2.5))

      visit(url)

      # Wait for page to fully load and add another small delay
      sleep(rand(0.5..1.5))
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
      puts decklist_text

      return { main_deck: [], sideboard: [] } unless decklist_text

      DecklistParsers::TextListParser.parse_decklist(decklist_text)
    end

    def source_type
      :mtggoldfish
    end
  end
end
