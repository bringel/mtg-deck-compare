# frozen_string_literal: true

require_relative "../decklist_parsers/parser_list.rb"

class DeckComparer
  attr_reader :deck_list_urls

  def initialize(deck_list_urls:)
    @deck_list_urls = deck_list_urls
  end

  def compare()
    %i[main_deck sideboard].to_h do |k|
      deck_cards = parsed_decks.map { |d| d.dig(:deck, k, :cards) }

      cards_in_all_decks = deck_cards.first.intersection(*deck_cards[1..-1])
      cards_in_all_decks_quantities =
        cards_in_all_decks.to_h do |c|
          card_quantities =
            parsed_decks.to_h do |d|
              [d[:index], d.dig(:deck, k, :quantities, c.name)]
            end
          [c.name, card_quantities]
        end

      decks_without_common = deck_cards.map { |deck| deck - cards_in_all_decks }

      cards_in_more_than_one = Set.new

      decks_without_common
        .combination(2)
        .each { |a, b| cards_in_more_than_one.merge(a & b) }
      cards_in_more_than_one_quantities =
        cards_in_more_than_one.to_h do |c|
          card_quantities =
            parsed_decks.to_h do |d|
              [d[:index], d.dig(:deck, k, :quantities, c.name)]
            end

          [c.name, card_quantities.compact]
        end

      decks_remaining =
        parsed_decks.to_h do |d|
          cards =
            d.dig(:deck, k, :cards) - cards_in_all_decks -
              cards_in_more_than_one.to_a

          card_names = cards.map { |c| c.name }
          quantities =
            d
              .dig(:deck, k, :quantities)
              .filter { |k, _v| card_names.include?(k) }
          [d[:index], { cards: cards, quantities: quantities }]
        end

      v = {
        common: {
          cards: cards_in_all_decks,
          quantities: cards_in_all_decks_quantities
        },
        multiple: {
          cards: cards_in_more_than_one.to_a,
          quantities: cards_in_more_than_one_quantities
        },
        decks_remaining: decks_remaining
      }
      [k, v]
    end
  end

  private

  def parsed_decks
    @deck_list_urls.map.with_index do |url, index|
      parser = DecklistParsers::ParserList.get_parser(url)
      { index: index, url: url, deck: parser.new(url).load_deck }
    end
  end
end
