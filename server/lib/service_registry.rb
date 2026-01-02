# frozen_string_literal: true

# Central registry for shared services
# Provides a single place to configure and access services like Redis
class ServiceRegistry
  @services = {}

  def self.register(name, instance)
    @services[name.to_sym] = instance
  end

  def self.method_missing(symbol, *args)
    if @services.has_key?(symbol)
      @services[symbol]
    else
      super(symbol, args)
    end
  end
end
