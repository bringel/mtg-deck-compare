# frozen_string_literal: true
require "active_support/inflector"
require "json"

class CamelCaseToSnakeCase
  def initialize(app)
    @app = app
  end

  def call(env)
    body = JSON.parse(env["rack.input"].gets)

    transformed_body = to_snake_case(body)

    env["rack.input"] = StringIO.new(JSON.generate(transformed_body))
    @app.call(env)
  end

  private

  def to_snake_case(value)
    case value
    when Array
      value.map { |v| to_snake_case(v) }
    when Hash
      value.to_h do |key, val|
        new_key = key.to_s.underscore
        new_value = to_snake_case(val)
        [new_key, new_value]
      end
    else
      value
    end
  end
end
