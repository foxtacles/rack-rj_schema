require File.expand_path('../spec_helper', __FILE__)
require File.expand_path('../interfaces/test_api/request_objects/post_method', __FILE__)
require File.expand_path('../interfaces/test_api/view_models/post_method', __FILE__)

Rack::RjSchemaObject.schema_file_root = 'spec'

describe Rack::RjSchema do
  before do
    stack Rack::RjSchema, namespace: 'Interfaces::TestApi', path: ''
  end

  describe 'processing POST request' do
    it 'succeeds' do
      post '/method', JSON.dump(int: 6), { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 200
      assert_equal({request_object_class: Interfaces::TestApi::RequestObjects::PostMethod}.to_json, last_response.body)
    end

    it 'fails due to request schema error' do
      post '/method', JSON.dump(int: 2), { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 400
    end

    it 'fails due to invalid JSON' do
      post '/method', '{asdddddd:', { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 400
    end
  end
end
