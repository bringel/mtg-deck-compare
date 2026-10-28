# frozen_string_literal: true

require_relative "./deck_data/deck_loader"
require_relative "../lib/service_registry.rb"

class DeckComparer
  attr_reader :deck_list_urls

  def initialize(deck_list_urls:)
    @deck_list_urls = deck_list_urls
  end

  def compare
    comparison = { common: {}, multiple: {}, decks_remaining: Hash.new { {} } }

    %i[main_deck sideboard].each do |section|
      deck_card_names =
        parsed_decks.map { |deck| deck.dig(:deck, section, :cards).map(&:name) }

      names_in_all_decks = find_common_cards(deck_card_names)
      names_without_common =
        deck_card_names.map { |names| names - names_in_all_decks }
      names_in_multiple = find_cards_in_multiple_decks(names_without_common)

      decks_remaining =
        build_remaining_decks_for_section(
          section: section,
          names_in_all: names_in_all_decks,
          names_in_multiple: names_in_multiple
        )

      comparison[:common][section] = {
        cards: cards_for_names(section: section, names: names_in_all_decks),
        quantities:
          cards_to_quantities(
            section: section,
            names: names_in_all_decks
          ).transform_values(&:compact)
      }
      comparison[:multiple][section] = {
        cards: cards_for_names(section: section, names: names_in_multiple),
        quantities:
          cards_to_quantities(
            section: section,
            names: names_in_multiple
          ).transform_values(&:compact)
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

  def find_common_cards(deck_card_names)
    deck_card_names.first.intersection(*deck_card_names[1..-1])
  end

  def find_cards_in_multiple_decks(names_without_common)
    names_in_multiple = Set.new
    names_without_common
      .combination(2)
      .each { |a, b| names_in_multiple.merge(a & b) }
    names_in_multiple.to_a
  end

  def build_remaining_decks_for_section(
    section:,
    names_in_all:,
    names_in_multiple:
  )
    shared_names = names_in_all + names_in_multiple

    parsed_decks.to_h do |deck|
      remaining_cards =
        deck
          .dig(:deck, section, :cards)
          .reject { |card| shared_names.include?(card.name) }
      card_names = remaining_cards.map(&:name)
      quantities =
        deck
          .dig(:deck, section, :quantities)
          .filter { |name, _| card_names.include?(name) }

      [deck[:index], { cards: remaining_cards, quantities: quantities }]
    end
  end

  def cards_for_names(section:, names:)
    names.map { |name| cards_by_name(section: section)[name] }
  end

  def cards_by_name(section:)
    @cards_by_name ||= {}
    @cards_by_name[section] ||= parsed_decks
      .flat_map { |deck| deck.dig(:deck, section, :cards) }
      .uniq(&:name)
      .to_h { |card| [card.name, card] }
  end

  def cards_to_quantities(section:, names:)
    names.to_h do |name|
      card_quantities =
        parsed_decks.to_h do |deck|
          [deck[:index], deck.dig(:deck, section, :quantities, name)]
        end
      [name, card_quantities]
    end
  end

  def parsed_decks
    @parsed_decks ||=
      begin
        deck_loader = DeckData::DeckLoader.new
        @deck_list_urls.map.with_index do |url, index|
          { index: index, url: url, deck: deck_loader.load_deck(url: url) }
        end
      end
  end
end
