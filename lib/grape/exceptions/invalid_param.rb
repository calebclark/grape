# encoding: utf-8
module Grape
  module Exceptions
    class InvalidParam < Base
      def initialize(message)
        super(message: message)
      end
    end
  end
end
