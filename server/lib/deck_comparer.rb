# frozen_string_literal: true

require_relative "../decklist_parsers/parser_list.rb"

class DeckComparer
  attr_reader :deck_list_urls

  def initialize(deck_list_urls:)
    @deck_list_urls = deck_list_urls
  end

  def compare()
    parsed_decks
      .combination(2)
      .to_h do |(a, b)|
        key = "#{a[:index]}_#{b[:index]}"

        common = {}
        a_only = {}
        b_only = {}
        quantities_differ = {}
        a_deck = a[:deck]
        b_deck = b[:deck]

        %i[main_deck sideboard].each do |k|
          common[k] = a_deck[k] & b_deck[k]
          a_only[k] = a_deck[k] - b_deck[k]
          b_only[k] = b_deck[k] - a_deck[k]

          same_name =
            a_only[k].map { |c| c[:card] } & b_only[k].map { |c| c[:card] }
          quantities_differ[k] = same_name.map do |c|
            a_value = a_deck[k].find { |v| v[:card] == c }
            b_value = b_deck[k].find { |v| v[:card] == c }
            {
              "#{a[:index]}_quantity".to_sym => a_value[:quantity],
              "#{b[:index]}_quantity".to_sym => b_value[:quantity],
              :card => c
            }
          end

          a_only[k] = a_only[k].reject { |c| same_name.include?(c[:card]) }

          b_only[k] = b_only[k].reject { |c| same_name.include?(c[:card]) }
        end

        [
          key,
          {
            :cards_in_common => common,
            "#{a[:index]}_only".to_sym => a_only,
            "#{b[:index]}_only".to_sym => b_only,
            :quantities_differ => quantities_differ
          }
        ]
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
