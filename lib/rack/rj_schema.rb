require 'json'

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/keys'

require 'rack/rj_schema_object'

module Rack
  class RjSchema
    REQUEST_OBJECT = 'rack.rj_schema.request_object'.freeze
    VIEW_MODEL = 'rack.rj_schema.view_model'.freeze
    FAILURE_RESPONSE = [400, {}, ['']].freeze

    def initialize(app, *args)
      @app = app
      @namespace = args.last[:namespace]
      @path = args.last[:path]
      @halt_when_invalid = args.last.key?(:halt_when_invalid) ? args.last[:halt_when_invalid] : true
      @verbose_response = args.last.key?(:verbose_response) ? args.last[:verbose_response] : false
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.content_type == 'application/json'
        begin
          env[REQUEST_OBJECT] = request_object(request)
        rescue JSON::ParserError
          return failure_response(['Invalid JSON'])
        end

        return failure_response(env[REQUEST_OBJECT].errors) if @halt_when_invalid && !env[REQUEST_OBJECT].valid?
      end

      code, headers, response = @app.call(env)
      return [code, headers, response] if code >= 300 || code < 200 || headers['Content-Type'] != 'application/json'

      body = view_model(request).to_json
      [code, headers.merge('Content-Type' => 'application/json', 'Content-Length' => body.bytesize), [body]]
    end

    private

    def failure_response(errors)
      return FAILURE_RESPONSE unless @verbose_response

      [
        FAILURE_RESPONSE[0],
        { CONTENT_TYPE => 'application/json'},
        [{ errors: errors }.to_json]
      ]
    end

    def request_object(request)
      klass = [@namespace.to_s, 'RequestObjects', *endpoint_path(request)].join('::')
      define_class(klass) unless Object.const_defined?(klass)
      klass.constantize.new(request_params(request))
    end

    def view_model(request)
      klass = [@namespace.to_s, 'ViewModels', *endpoint_path(request)].join('::')
      define_class(klass) unless Object.const_defined?(klass)
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

    def define_class(path)
      modules = ["Object"] + path.split("::")
      klass = modules.pop

      result = modules.reduce do |sum, m|
        target = sum + "::" + m
        sum.constantize.const_set(m, Module.new) unless Object.const_defined?(target)
        target
      end

      result.constantize.const_set(klass, Class.new(Rack::RjSchemaObject))
    end
  end
end
