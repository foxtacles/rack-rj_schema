require 'json'
require 'rj_schema'

module Rack
  class RjSchemaObject
    class SchemaValidationError < StandardError; end

    attr_reader :attributes
    attr_reader :errors
    attr_reader :last_url

    def initialize(attributes, unveil: nil, raise_on_error: false)
      @attributes = attributes
      @errors = self.class.validate(to_json)

      raise SchemaValidationError.new(errors) if !valid? && raise_on_error

      if valid? && !@attributes.is_a?(Array)
        if unveil
          @unveil = unveil.is_a?(Array) ? unveil : [unveil]
          @unveil.each { |key| @attributes.merge!(@attributes[key]) }
        end

        @attributes.each_key do |key|
          instance_variable_set("@#{key}", @attributes[key])
          self.class.send(:attr_reader, key) unless respond_to?(key)
        end
      end
    end

    def valid?
      errors.empty?
    end

    def to_json(_opts = {})
      @to_json ||= JSON.dump(@attributes)
    end

    def payload
      return attributes if @unveil.nil?

      attributes.except(*attributes.slice(*@unveil).values.flat_map(&:keys))
    end

    def self.method
      name.demodulize.underscore.split('_').first
    end

    def self.api
      name.split('::')[0..1].join('::')
    end

    def self.schema
      modules = name.split('::').insert(2, 'Schema').join('::')
      "#{schema_file_root}/#{modules.underscore}.json"
    end

    def self.schema_collection
      modules = name.split('::')[0..1].insert(2, 'Schema').join('::')
      Dir["#{schema_file_root}/#{modules.underscore}/**/*.json"]
    end

    def self.validator
      @@validator_cache ||= {}
      return @@validator_cache[api] unless @@validator_cache[api].nil?

      @@validator_cache[api] = ::RjSchema::Validator.new(
        schema_collection.each_with_object({}) { |file, hash| hash[file.include?('/definitions/') ? ::File.basename(file) : file] = ::File.new(file) }
      )
    end

    def self.validate(attributes)
      validator.validate(schema.to_sym, attributes)
    end

    def self.schema_file_root
      @@schema_file_root ||= 'src'
    end

    def self.schema_file_root=(schema_file_root)
      @@schema_file_root = schema_file_root
    end
  end
end
