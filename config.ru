# frozen_string_literal: true

require_relative 'server/api_app'
require_relative 'server/static_app'

map('/api') { run ApiApp }
map('/') { run StaticApp }
