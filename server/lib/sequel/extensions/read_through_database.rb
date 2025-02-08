# frozen_string_literal: true

module Database
  module ReadThroughDatabase
    def read_through
      data = all
      yield DB[first_source_table] if block_given? && data.length.zero?

      all
    end
  end
  Sequel::Dataset.register_extension(
    :read_through_database,
    ReadThroughDatabase
  )
end
