require 'minitest/autorun'
require 'rack'
require 'rack/test'
require 'rack/builder'
require 'json'

require File.expand_path('../../lib/rack/rj_schema', __FILE__)

class TestApp
  def call(env)
    request_object = env[Rack::RjSchema::REQUEST_OBJECT]
    env[Rack::RjSchema::VIEW_MODEL] = {request_object_class: request_object.class.name}
    [200, {'Content-Type' => 'application/json'}, {}]
  end
end

class Minitest::Spec
  include Rack::Test::Methods

  def app(*middleware)
    @builder = Rack::Builder.new
    @builder.use(*@stack)
    @builder.run TestApp.new
    @builder.to_app
  end

  def stack(*middleware)
    @stack = middleware
  end
end
