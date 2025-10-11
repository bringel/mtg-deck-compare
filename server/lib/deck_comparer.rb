# frozen_string_literal: true

require_relative "../decklist_parsers/parser_list.rb"

class DeckComparer
  attr_reader :deck_list_urls

  def initialize(deck_list_urls:)
    @deck_list_urls = deck_list_urls
  end

  def compare
    comparison = { common: {}, multiple: {}, decks_remaining: Hash.new { {} } }

    %i[main_deck sideboard].each do |section|
      deck_cards = parsed_decks.map { |deck| deck.dig(:deck, section, :cards) }

      cards_in_all_decks = find_common_cards(deck_cards)
      cards_in_all_decks_quantities =
        cards_to_quantities(section: section, cards: cards_in_all_decks)

      decks_without_common = deck_cards.map { |deck| deck - cards_in_all_decks }
      cards_in_multiple = find_cards_in_multiple_decks(decks_without_common)
      cards_in_multiple_quantities =
        cards_to_quantities(section: section, cards: cards_in_multiple)

      decks_remaining =
        build_remaining_decks_for_section(
          section: section,
          cards_in_all: cards_in_all_decks,
          cards_in_multiple: cards_in_multiple
        )

      comparison[:common][section] = {
        cards: cards_in_all_decks.compact,
        quantities: cards_in_all_decks_quantities.transform_values(&:compact)
      }
      comparison[:multiple][section] = {
        cards: cards_in_multiple.to_a.compact,
        quantities: cards_in_multiple_quantities.transform_values(&:compact)
      }

      decks_remaining.each do |index, deck_portion|
        comparison[:decks_remaining][index] = comparison[:decks_remaining][
          index
        ].merge!({ section => deck_portion })
      end
    end
    comparison
  end

  private

  def find_common_cards(deck_cards)
    deck_cards.first.intersection(*deck_cards[1..-1])
  end

  def find_cards_in_multiple_decks(decks_without_common)
    cards_in_multiple = Set.new
    decks_without_common
      .combination(2)
      .each { |a, b| cards_in_multiple.merge(a & b) }
    cards_in_multiple
  end

  def build_remaining_decks_for_section(
    section:,
    cards_in_all:,
    cards_in_multiple:
  )
    parsed_decks.to_h do |deck|
      remaining_cards =
        deck.dig(:deck, section, :cards) - cards_in_all - cards_in_multiple.to_a
      card_names = remaining_cards.map(&:name)
      quantities =
        deck
          .dig(:deck, section, :quantities)
          .filter { |name, _| card_names.include?(name) }

      [deck[:index], { cards: remaining_cards, quantities: quantities }]
    end
  end

  def cards_to_quantities(section:, cards:)
    cards.to_h do |card|
      card_quantities =
        parsed_decks.to_h do |deck|
          [deck[:index], deck.dig(:deck, section, :quantities, card.name)]
        end
      [card.name, card_quantities]
    end
  end

  def parsed_decks
    @deck_list_urls.map.with_index do |url, index|
      parser =
        DecklistParsers::ParserList.get_parser(
          url,
          redis: ApiApp.settings.redis
        )
      { index: index, url: url, deck: parser.new(url).get_deck }
    end
  end
end
