# frozen_string_literal: true

require "sinatra/base"
require "json"
require "sequel"
require "dotenv"
require "redis"
require "connection_pool"

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

  configure do
    r = ConnectionPool::Wrapper.new { Redis.new(url: ENV["REDIS_URL"]) }

    set :redis, r
  end

  get "/deck_info" do
    parser = DecklistParsers::ParserList.get_parser(request.params["url"])

    parser.new(request.params["url"]).load_deck_info.to_json
  end

  get "/load_deck" do
    parser = DecklistParsers::ParserList.get_parser(request.params["url"])
    JSON.generate(
      parser.new(request.params["url"], redis: settings.redis).get_deck.to_h
    )
  end

  post "/compare_decks" do
    body = JSON.parse(request.body.read)

    DeckComparer.new(deck_list_urls: body["deckListURLs"]).compare.to_json
  end

  get "/check_card/:set/:number" do
    JSON.dump(
      CardsService
        .new(redis: settings.redis)
        .get_card_from_set(
          set_code: params["set"],
          set_number: params["number"]
        )
        .to_h
    )
  end

  post "/check_cards" do
    JSON.generate(
      CardsService
        .new(redis: settings.redis)
        .get_cards(card_hashes: JSON.parse(request.body.read))
        .transform_values(&:to_h)
    )
  end
end
