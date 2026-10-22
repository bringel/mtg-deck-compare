# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../server/decklist_parsers/text_list_parser"

class TextListParserTest < Minitest::Test
  Parser = DecklistParsers::TextListParser

  def test_quantity_first_and_last_formats
    result = Parser.parse_decklist("4 Lightning Bolt\nCounterspell 2")

    assert_equal [
                   { quantity: 4, name: "Lightning Bolt" },
                   { quantity: 2, name: "Counterspell" }
                 ],
                 result[:main_deck]
  end

  def test_set_and_number_format
    result = Parser.parse_decklist("1 Sol Ring (C21) 263")

    assert_equal [
                   {
                     quantity: 1,
                     name: "Sol Ring",
                     set_code: "C21",
                     set_number: "263"
                   }
                 ],
                 result[:main_deck]
  end

  def test_arena_style_section_headers
    list = <<~LIST
      Commander
      1 Atraxa, Praetors' Voice

      Deck
      1 Sol Ring

      Sideboard
      1 Negate
    LIST

    result = Parser.parse_decklist(list)

    assert_equal ["Atraxa, Praetors' Voice"], result[:commander].map { _1[:name] }
    assert_equal ["Sol Ring"], result[:main_deck].map { _1[:name] }
    assert_equal ["Negate"], result[:sideboard].map { _1[:name] }
  end

  def test_headers_with_colons_and_counts
    result =
      Parser.parse_decklist("Deck (2):\n2 Island\nSIDEBOARD:\n1 Negate")

    assert_equal ["Island"], result[:main_deck].map { _1[:name] }
    assert_equal ["Negate"], result[:sideboard].map { _1[:name] }
  end

  def test_card_names_that_start_like_headers_are_not_headers
    result = Parser.parse_decklist("Commander's Plate 1\nDeckhand 2")

    assert_empty result[:commander]
    assert_equal ["Commander's Plate", "Deckhand"],
                 result[:main_deck].map { _1[:name] }
  end

  def test_blank_lines_are_ignored_by_default
    result = Parser.parse_decklist("4 Island\n\n2 Negate")

    assert_equal 2, result[:main_deck].length
    assert_empty result[:sideboard]
  end

  def test_blank_line_can_start_the_sideboard
    result =
      Parser.parse_decklist(
        "\r\n4 Island\r\n\r\n2 Negate\r\n",
        blank_line_starts_sideboard: true
      )

    assert_equal ["Island"], result[:main_deck].map { _1[:name] }
    assert_equal ["Negate"], result[:sideboard].map { _1[:name] }
  end
end
