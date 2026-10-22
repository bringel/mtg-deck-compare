require 'dotenv/tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

task default: :test

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] => :dotenv do |t, args|
    require "sequel/core"
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    Sequel.connect(ENV.fetch("DATABASE_URL")) do |db|
      Sequel::Migrator.run(db, "server/db/migrations", target: version)
    end
  end
end

namespace :fixtures do
  desc "Record a response body as a parser test fixture, e.g. " \
       "rake 'fixtures:record[aetherhub,https://aetherhub.com/Deck/...,deck.html]'"
  task :record, [:source, :url, :filename] => :dotenv do |_t, args|
    require_relative "server/fetchers/http_fetcher"

    source, url, filename = args.values_at(:source, :url, :filename)
    abort "usage: rake 'fixtures:record[source,url,filename]'" unless source && url && filename

    # the same fetcher the app uses, minus rate limiting so Redis isn't needed
    response = Fetchers::HttpFetcher.new(source_type: source.to_sym).get(url)

    path = File.join(__dir__, "test", "fixtures", source, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, response.body)
    puts "wrote #{response.body.bytesize} bytes to #{path}"
  end
end
