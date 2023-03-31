# frozen_string_literal: true

require "sinatra/base"

class App < Sinatra::Application
  set :public_folder, File.expand_path("#{__dir__}/../public")

  get "/*" do
    File.read(File.expand_path("#{settings.public_folder}/index.html"))
  end
end
