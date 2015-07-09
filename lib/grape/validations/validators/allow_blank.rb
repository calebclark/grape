module Grape
  module Validations
    class AllowBlankValidator < Base
      def validate_param!(attr_name, params)
        return if @option || !params.is_a?(Hash)

        value = params[attr_name]
        value = value.strip if value.respond_to?(:strip)

        key_exists = params.key?(attr_name)

        if @scope.root?
          # root scope. validate if it's a required param. if it's optional, validate only if key exists in hash
          should_validate = @required || key_exists
        else # nested scope
          should_validate = # required param, and scope contains some values (if scoping element contains no values, treat as blank)
            # first check if nested scope is dependent (i.e., a given block was used)
            (!@scope.dependent_on || params.key?(@scope.dependent_on)) && (
              (@required && params.present?) ||
              # optional param but key inside scoping element exists
              (!@required && params.key?(attr_name) && (!@scope.dependent_on || params.key?(@scope.dependent_on)))
            )
        end

        return unless should_validate

        unless value == false || value.present?
          fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :blank
        end
      end
    end
  end
end
