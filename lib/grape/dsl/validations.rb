require 'active_support/concern'

module Grape
  module DSL
    module Validations
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        # Clears all defined parameters and validations.
        def reset_validations!
          unset_namespace_stackable :declared_params
          unset_namespace_stackable :validations
          unset_namespace_stackable :params
        end

        # Opens a root-level ParamsScope, defining parameter coercions and
        # validations for the endpoint.
        # @yield instance context of the new scope
        def params(&block)
          Grape::Validations::ParamsScope.new(api: self, type: Hash, &block)
        end

        def default_allow_blank(boolean)
          namespace_setting(:default_allow_blank, boolean==true)
        end

        def document_attribute(names, opts)
          route_setting(:description, {}) unless route_setting(:description)

          route_setting(:description)[:params] ||= {}

          setting = route_setting(:description)[:params]
          Array(names).each do |name|
            setting[name[:full_name].to_s] ||= {}
            setting[name[:full_name].to_s].merge!(opts)

            namespace_stackable(:params, name[:full_name].to_s => opts)
          end
        end
      end
    end
  end
end
