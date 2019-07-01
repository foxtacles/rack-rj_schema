require 'json'
require 'active_support/core_ext/string/inflections'

module Rack
  class RjSchema
    REQUEST_OBJECT = 'rack.rj_schema.request_object'.freeze
    VIEW_MODEL = 'rack.rj_schema.view_model'.freeze
    FAILURE_RESPONSE = [400, {}, ['']].freeze

    def initialize(app, namespace:, path:, halt_when_invalid: true)
      @app = app
      @namespace = namespace
      @path = path
      @halt_when_invalid = halt_when_invalid
    end

    def call(env)
      request = Rack::Request.new(env)

      begin
        env[REQUEST_OBJECT] = request_object(request)
      rescue JSON::ParserError
        return FAILURE_RESPONSE
      end

      return FAILURE_RESPONSE if @halt_when_invalid && !env[REQUEST_OBJECT].valid?

      code, headers, body = @app.call(env)
      [code, headers.merge('Content-Type' => 'application/json'), view_model(request).to_json]
    end

    private

    def request_object(request)
      klass = [@namespace.to_s, 'RequestObjects', *endpoint_path(request)].join('::')
      klass.constantize.new(request_params(request))
    end

    def view_model(request)
      klass = [@namespace.to_s, 'ViewModels', *endpoint_path(request)].join('::')
      klass.constantize.new(request.env[VIEW_MODEL] || {})
    end

    def endpoint_path(request)
      parts = request.path.sub(@path, '')[1..-1].split('/').map(&:camelize)
      parts << '' if request.path[-1] == '/'
      parts[-1] = request.request_method.humanize + parts[-1]
      parts
    end

    def request_params(request)
      body = request.body.read
      request.body.rewind

      %w[GET DELETE].include?(request.request_method) ? request.params.deep_symbolize_keys : JSON.parse(body, symbolize_names: true)
    end
  end
end
