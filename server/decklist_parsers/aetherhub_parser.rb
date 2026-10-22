# frozen_string_literal: true

require_relative "./decklist_parser"

module DecklistParsers
  class AetherhubParser < DecklistParser
    URL_PATTERN = %r{(?:https?://)?(?:www\.)?aetherhub\.com/Deck/.*}

    SET_CODE_CONVERSIONS = {
      "dar" => "dom" # for some reason, some cards from Dominaria show up with the code DAR, but scryfall doesn't like it
    }.freeze

    def self.source_type
      :aetherhub
    end

    def parse
      doc = html(fetcher.get(url))

      deck_id = doc.at_css("[data-deckid].mtgaExport")&.[]("data-deckid")
      raise extraction_error("Couldn't find the deck id on the page") unless deck_id

      deck =
        fetcher.get(
          "https://aetherhub.com/Deck/FetchMtgaDeckJson",
          params: {
            "deckId" => deck_id,
            "lang" => 0,
            "simple" => false
          },
          accept: :json
        ).json

      sections = split_sections(deck["convertedDeck"])

      Models::ParsedDeck.new(
        name: deck_name(doc),
        author: doc.at_css('a[href^="/User"]')&.text&.strip,
        main_deck: sections[:main_deck].map { |c| card_to_hash(card_data: c) },
        sideboard: sections[:sideboard].map { |c| card_to_hash(card_data: c) }
      )
    end

    private

    def deck_name(doc)
      page_title = doc.at_css("title")&.text.to_s
      page_title.split("-", 2).last.to_s.gsub(/youtube video/i, "").strip
    end

    # convertedDeck is a flat list where entries without a quantity are
    # section headers ("Deck", "Commander", "Sideboard") for the cards after them
    def split_sections(converted_deck)
      sections = { main_deck: [], sideboard: [] }
      category = ""

      Array(converted_deck).each do |card|
        category = card["name"].to_s.downcase if card["quantity"].nil?
        next unless card["quantity"] && card["name"]

        case category
        when "deck", "commander"
          sections[:main_deck] << card
        when "sideboard"
          sections[:sideboard] << card
        end
      end

      sections
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
        set_code = card_data["set"].downcase
        {
          set_code: SET_CODE_CONVERSIONS.fetch(set_code, set_code),
          set_number: card_data["number"].to_i,
          quantity: card_data["quantity"]
        }
      end
    end
  end
end
