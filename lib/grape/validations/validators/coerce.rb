require 'grape/exceptions/invalid_param'

module Grape
  class API
    Boolean = Virtus::Attribute::Boolean # rubocop:disable ConstantName
  end

  module Validations
    class CoerceValidator < Base
      def validate_param!(attr_name, params)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce unless params.is_a? Hash
        if (@option.is_a?(Array) || @option.is_a?(Set))
          validate_array_of_values(@option.first, params[attr_name], attr_name, params)
        else
          validate_single_value(@option, params[attr_name], attr_name, params)
        end
      end

      def validate_array_of_values(type, values, attr_name, params)
        return if values.nil?
        if !values.is_a?(Array)
          fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: 'is invalid Array'
        end
        params[attr_name] = values.map do |value|
          validate_and_coerce_value!(type, value, attr_name, params, true)
        end
      end

      def validate_single_value(type, value, attr_name, params)
        params[attr_name] = validate_and_coerce_value!(type, value, attr_name, params)
      end

      def validate_and_coerce_value!(type, value, attr_name, params, is_from_array=false)
        new_value = coerce_value(type, value, params, attr_name, is_from_array)
        return new_value if _valid_single_type?(type, new_value)
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce
      rescue Grape::Exceptions::InvalidParam => e
        fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: e.message
      end

      class InvalidValue; end

      private

      def _valid_single_type?(klass, val)
        # allow nil, to ignore when a parameter is absent
        return true if val.nil?
        if klass.ancestors.include?(Virtus::Attribute::Boolean)
          val.is_a?(TrueClass) || val.is_a?(FalseClass) || (val.is_a?(String) && val.empty?)
        elsif klass == Rack::Multipart::UploadedFile
          val.is_a?(Hashie::Mash) && val.key?(:tempfile)
        elsif [::DateTime, ::Date, ::Numeric].any? { |vclass| vclass >= klass }
          return true if val.is_a?(String) && val.empty?
          val.is_a?(klass)
        else
          val.is_a?(klass)
        end
      end

      def coerce_value(type, val, params, attr_name, is_from_array)
        # Don't coerce things other than nil to Arrays or Hashes
        return val || []      if type == Array
        return val || Set.new if type == Set
        return val || {}      if type == Hash

        # To support custom types that Virtus can't easily coerce, use a custom
        # method. Custom types must implement a `parse` class method.
        if ParameterTypes.custom_type?(type)
          args = [val, ParamObject.new(@attrs, @doc_attrs, @scope, params, attr_name, is_from_array)]
          type.send(:parse, *args[0...type.method(:parse).arity])
        else
          Virtus::Attribute.build(type).coerce(val)
        end

      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb:75)
      rescue Grape::Exceptions::InvalidParam => e
        raise
      rescue Exception => e
        puts e.message
        puts e.backtrace
        InvalidValue.new
      end

      class ParamObject
        attr_reader :attrs, :doc_attrs, :scope, :params, :attr_name, :is_array
        def initialize(attrs, doc_attrs, scope, params, attr_name, is_array)
          @attrs = attrs
          @doc_attrs = doc_attrs
          @scope = scope
          @params = params
          @attr_name = attr_name
          @is_from_array = is_array
        end
      end

    end
  end
end
