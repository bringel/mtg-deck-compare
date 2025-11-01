# frozen_string_literal: true
require "faraday"
require "nokogiri"

require_relative "./decklist_parser"
require_relative "../services/cards_service"
require_relative "../models/deck"

module DecklistParsers
  class AetherhubParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?aetherhub\.com/Deck/.*}

    def load_deck_info
      @page_content = Faraday.get(@url)
      @doc = Nokogiri.HTML(@page_content.body)

      page_title = @doc.css("title").text
      name = page_title.split("-", 2).last.gsub(/youtube video/i, "").strip
      user = @doc.css('a[href^="/User"]').first.text.strip

      { name: name, author: user, source_type: :aetherhub, source_url: @url }
    end

    def load_deck
      info = load_deck_info
      cards = get_card_info

      main_deck_card_hashes =
        cards[:main_deck].map { |c| card_to_hash(card_data: c) }
      sideboard_card_hashes =
        cards[:sideboard].map { |c| card_to_hash(card_data: c) }
      main_deck = fetch_cards(card_hashes: main_deck_card_hashes)
      sideboard = fetch_cards(card_hashes: sideboard_card_hashes)

      Models::Deck.new(**info, main_deck: main_deck, sideboard: sideboard)
    end

    private

    def get_card_info
      deck_id = @doc.css("[data-deckid].mtgaExport").first["data-deckid"]

      deck_response =
        Faraday.get(
          "https://aetherhub.com/Deck/FetchMtgaDeckJson",
          { "deckId" => deck_id, "lang" => 0, "simple" => false }
        )

      deck = JSON.parse(deck_response.body)

      set_code_conversions = {
        "dar" => "dom" # for some reason, some cards from Dominaria show up with the code DAR, but scryfall doesn't like it
      }

      main_deck = []
      sideboard = []

      category = ""
      deck["convertedDeck"].each do |card|
        category = card["name"] if card["quantity"].nil?

        if card["quantity"] && card["name"]
          if category.downcase == "deck" || category.downcase == "commander"
            main_deck << card.except("cardId")
          elsif category.downcase == "sideboard"
            sideboard << card.except("cardId")
          end
        end
      end

      main_deck =
        main_deck.map do |c|
          if set_code_conversions.key?(c["set"].downcase)
            c.merge({ "set" => set_code_conversions[c["set"].downcase] })
          else
            c
          end
        end

      sideboard =
        sideboard.map do |c|
          if set_code_conversions.key?(c["set"].downcase)
            c.merge({ "set" => set_code_conversions[c["set"].downcase] })
          else
            c
          end
        end

      return { main_deck:, sideboard: }
    end

    def card_to_hash(card_data:)
      if card_data["number"].nil? || card_data["number"].match?(/\d+-\w+/) ||
           card_data["number"].to_i > 9999
        # for some reason, there are some cards with "numbers" like 999-AC or 999-E
        # or the number is greater than 4 digits which shouldn't be possible right now
        # but currently is on aether hub for pioneer masters
        # I think maybe they're older alchemy cards that aetherhub is representing wierdly
        # if that's the case scryfall wont find them so we can just search them by name
        { name: card_data["name"], quantity: card_data["quantity"] }
      else
        {
          set_code: card_data["set"].downcase,
          set_number: card_data["number"].to_i,
          quantity: card_data["quantity"]
        }
      end
    end
  end
end
