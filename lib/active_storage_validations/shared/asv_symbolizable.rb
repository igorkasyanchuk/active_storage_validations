# frozen_string_literal: true

module ActiveStorageValidations
  module ASVSymbolizable
    extend ActiveSupport::Concern

    class_methods do
      def to_sym
        validator_class = self.name.split("::").last
        validator_class.sub(/Validator/, "").underscore.to_sym
      end
    end
  end
end
