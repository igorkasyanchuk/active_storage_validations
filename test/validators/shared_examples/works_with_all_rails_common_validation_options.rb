require 'validators/shared_examples/works_with_allow_blank_option'
require 'validators/shared_examples/works_with_allow_nil_option'
require 'validators/shared_examples/works_with_if_option'
require 'validators/shared_examples/works_with_message_option'
require 'validators/shared_examples/works_with_on_option'
require 'validators/shared_examples/works_with_unless_option'
require 'validators/shared_examples/works_with_strict_option'

module WorksWithAllRailsCommonValidationOptions
  extend ActiveSupport::Concern

  # You can find all Rails common validation options here:
  # https://guides.rubyonrails.org/active_record_validations.html#common-validation-options

  included do
    %i(allow_nil allow_blank if on strict unless message).each do |validation_option|
      describe ":#{validation_option}" do
        include "WorksWith#{validation_option.to_s.camelize}Option".constantize
      end
    end
  end
end
