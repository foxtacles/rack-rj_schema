require 'rack/rj_schema_object'

module Interfaces
  module TestApi
    module ViewModels
      class PostMethod < Rack::RjSchemaObject
        def initialize(attributes)
          super(attributes, raise_on_error: true)
        end
      end
    end
  end
end
