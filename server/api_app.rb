# frozen_string_literal: true

require "sinatra/base"
require "json"
require "sequel"
require "dotenv"
require "redis"
require "connection_pool"

require_relative "./decklist_parsers/errors"
require_relative "./lib/deck_comparer.rb"
require_relative "./lib/sequel/extensions/read_through_database.rb"
require_relative "./lib/service_registry.rb"
require_relative "./middleware/camel_case_to_snake_case"
require_relative "./middleware/snake_case_to_camel_case"
require_relative "./services/deck_service"

Dotenv.load

# DB = Sequel.connect(ENV["DATABASE_URL"])
# DB.extension :pg_array
# DB.extension :pg_json
# DB.extension :read_through_database

# Sequel.extension :pg_array_ops
# Sequel.extension :pg_json_ops

# Configure shared services
ServiceRegistry.register(
  :redis,
  ConnectionPool::Wrapper.new do
    Redis.new(
      url: ENV["REDIS_URL"],
      ssl_params: {
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
    )
  end
)

class ApiApp < Sinatra::Application
  set :public_folder, File.expand_path("#{__dir__}/../public")
  set :default_content_type, :json

  # Allow CORS for development (Vite dev server)
  # In production, the static app serves from same origin so this only affects dev
  configure :development do
    set :protection, except: [:json_csrf]
  end

  # let the error handlers below run in development too, instead of
  # Sinatra's HTML debug page
  set :show_exceptions, :after_handler

  use CamelCaseToSnakeCase
  use SnakeCaseToCamelCase

  error DecklistParsers::Error do
    e = env["sinatra.error"]
    status e.http_status
    JSON.generate({ error: e.to_h })
  end

  # replaces Sinatra's HTML 404 page (which it registers itself in development)
  error Sinatra::NotFound do
    status 404
    JSON.generate({ error: { code: "not_found", message: "Not found" } })
  end

  # anything unexpected still gets a JSON body (the camelCase middleware
  # expects one); the backtrace is logged by Sinatra's dump_errors.
  # This has to be StandardError, not a bare `error do`: Sinatra stops walking
  # an exception's ancestors before Exception, so that would never match
  error StandardError do
    status 500
    JSON.generate(
      {
        error: {
          code: "internal_error",
          message: "Something went wrong on our end"
        }
      }
    )
  end

  get "/load_deck" do
    JSON.generate(DeckService.new.load_from_url(request.params["url"]).to_h)
  end

  post "/create_manual_deck" do
    deck_service = DeckService.new

    body = JSON.parse(request.body.read)
    res =
      deck_service.save_manual_deck(
        list: body["list"],
        name: body["name"],
        url: body["url"],
        author: body["author"]
      )

    JSON.generate(res.merge({ deck: res[:deck].to_h }))
  end

  post "/compare_decks" do
    body = JSON.parse(request.body.read)

    DeckComparer.new(deck_list_urls: body["deck_list_urls"]).compare.to_json
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
      CardsService
        .new
        .get_cards(card_hashes: JSON.parse(request.body.read))
        .transform_values(&:to_h)
    )
  end
end
