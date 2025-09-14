# frozen_string_literal: true

require "sinatra/base"
require "json"
require "sequel"
require "dotenv"
require "redis"

require_relative "./decklist_parsers/parser_list.rb"
require_relative "./lib/deck_comparer.rb"
require_relative "./lib/sequel/extensions/read_through_database.rb"

Dotenv.load

# DB = Sequel.connect(ENV["DATABASE_URL"])
# DB.extension :pg_array
# DB.extension :pg_json
# DB.extension :read_through_database

# Sequel.extension :pg_array_ops
# Sequel.extension :pg_json_ops

REDIS = Redis.new

class ApiApp < Sinatra::Application
  set :public_folder, File.expand_path("#{__dir__}/../public")
  set :default_content_type, :json
  # set :redis, Redis.new #Redis.new(url: ENV["REDIS_URL"])

  post "/load_deck" do
    body = JSON.parse(request.body.read)
    parser = DecklistParsers::ParserList.get_parser(body["url"])

    parser.new(body["url"]).load_deck.to_json
  end

  post "/compare_decks" do
    body = JSON.parse(request.body.read)

    DeckComparer.new(deck_list_urls: body["deckListURLs"]).compare.to_json
  end

  get "/check_card/:set/:number" do
    JSON.dump(
      CardsService
        .new
        .get_card_from_set(
          set_code: params["set"],
          set_number: params["number"]
        )
        .to_h
    )
  end

  post "/check_cards" do
    JSON.generate(
      ScryfallService
        .new
        .get_cards(card_hashes: JSON.parse(request.body.read))
        .map(&:to_h)
    )
  end
end
