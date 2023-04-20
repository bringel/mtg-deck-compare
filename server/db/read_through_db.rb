# frozen_string_literal: true

module Data
  class ReadThroughDatabase
    attr_reader :table_name

    def initialize(table_name:)
      @table_name = table_name
      @dataset = DB[table_name]
    end

    def read_through
      data = @dataset.all

      yield DB[table_name] if block_given? && data.length.zero?

      data
    end

    def method_missing(m, *args, &block)
      @dataset = @dataset.send(m, *args, &block)

      self
    end

    def respond_to_missing?(method_name, include_private = false)
      @dataset.respond_to?(method_name, include_private)
    end
  end
end
