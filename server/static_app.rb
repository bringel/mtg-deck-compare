# frozen_string_literal: true

require 'sinatra/base'

class StaticApp < Sinatra::Base
  set :public_folder, File.expand_path("#{__dir__}/../public")

  get '/*' do
    send_file File.join(settings.public_folder, 'index.html')
  end
end
