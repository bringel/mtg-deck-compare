# frozen_string_literal: true
require "active_support/inflector"
require "json"

class SnakeCaseToCamelCase
  DONT_CAMELIZE_KEYS = %w[quantities]

  def initialize(app)
    @app = app
  end

  def call(env)
    response = @app.call(env)

    body = JSON.parse(response.last.join("\n"))

    transformed_body = to_camel_case(body)
    body_string = JSON.generate(transformed_body)
    response[2] = StringIO.new(body_string)
    response[1] = response[1].to_h do |header_name, value|
      if header_name.downcase == "content-length"
        [header_name, body_string.bytesize.to_s]
      else
        [header_name, value]
      end
    end
    response
  end

  private

  def to_camel_case(value)
    case value
    when Array
      value.map { |v| to_camel_case(v) }
    when Hash
      value.to_h do |key, val|
        new_key = key.to_s.camelize(:lower)
        new_value =
          DONT_CAMELIZE_KEYS.include?(new_key) ? val : to_camel_case(val)
        [new_key, new_value]
      end
    else
      value
    end
  end
end
