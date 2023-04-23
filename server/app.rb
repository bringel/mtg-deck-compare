# frozen_string_literal: true

require "sinatra/base"
require "sequel"
require "dotenv"

Dotenv.load

DB = Sequel.connect(ENV["DATABASE_URL"])
DB.extension :pg_array
DB.extension :pg_json
Sequel.extension :pg_array_ops
Sequel.extension :pg_json_ops

class App < Sinatra::Application
  set :public_folder, File.expand_path("#{__dir__}/../public")

  post "/deckurl" do
  end

  get "/*" do
    File.read(File.expand_path("#{settings.public_folder}/index.html"))
  end
end
