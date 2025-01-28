# frozen_string_literal: true

require "sinatra/base"
require "sequel"
require "dotenv"

require_relative "./decklist_parsers/parser_list.rb"
require_relative "./lib/deck_comparer.rb"

Dotenv.load

DB = Sequel.connect(ENV["DATABASE_URL"])
DB.extension :pg_array
DB.extension :pg_json
Sequel.extension :pg_array_ops
Sequel.extension :pg_json_ops

class ApiApp < Sinatra::Application
  set :public_folder, File.expand_path("#{__dir__}/../public")
  set :default_content_type, :json

  post "/load_deck" do
    body = JSON.parse(request.body.read)
    parser = DecklistParsers::ParserList.get_parser(body["url"])

    parser.new(body["url"]).load_deck.to_json
  end

  post "/compare_decks" do
    body = JSON.parse(request.body.read)

    DeckComparer.new(deck_list_urls: body["deckListURLs"]).compare.to_json
  end
end
