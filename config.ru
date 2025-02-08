# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(__dir__, "server/lib"))

require_relative "server/api_app"
require_relative "server/static_app"

map("/api") { run ApiApp }
map("/") { run StaticApp }
