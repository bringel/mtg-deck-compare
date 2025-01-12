require 'dotenv/tasks'

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