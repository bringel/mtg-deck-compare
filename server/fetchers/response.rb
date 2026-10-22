# frozen_string_literal: true
require "json"

module Fetchers
  Response =
    Data.define(:status, :headers, :body, :url) do
      def success?
        status.between?(200, 299)
      end

      def json
        JSON.parse(body)
      end

      def header(name)
        headers[name] || headers[name.downcase]
      end
    end
end
