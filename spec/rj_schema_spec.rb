require File.expand_path('../spec_helper', __FILE__)

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
      assert_equal(last_response.headers['Content-Length'].to_i, last_response.body.bytesize)
    end

    it 'fails due to request schema error' do
      post '/method', JSON.dump(int: 2), { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 400
    end

    it 'fails due to invalid JSON' do
      post '/method', '{asdddddd:', { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 400
    end

    it 'forwards invalid response' do
      post '/method', JSON.dump(int: 6), { 'CONTENT_TYPE' => 'application/json', 'ERROR' => 'true' }

      assert last_response.status == 400
      assert_equal('error', last_response.body)
    end
  end

  describe 'processing GET request' do
    it 'succeeds' do
      get '/method', {int: 6}, { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 200
      assert_equal({request_object_class: Interfaces::TestApi::RequestObjects::GetMethod}.to_json, last_response.body)
    end

    it 'fails due to request schema error' do
      get '/method', {int: 2}, { 'CONTENT_TYPE' => 'application/json' }

      assert last_response.status == 400
    end
  end
end
