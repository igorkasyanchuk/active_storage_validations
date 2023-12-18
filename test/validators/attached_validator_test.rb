# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/does_not_work_with_allow_blank_option'
require 'validators/shared_examples/does_not_work_with_allow_nil_option'
require 'validators/shared_examples/works_with_if_option'
require 'validators/shared_examples/works_with_message_option'
require 'validators/shared_examples/works_with_on_option'
require 'validators/shared_examples/works_with_unless_option'
require 'validators/shared_examples/works_with_strict_option'

describe ActiveStorageValidations::AttachedValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Attached::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    # Checked by Rails options tests
  end

  describe 'Rails options' do
    %i(allow_nil allow_blank).each do |unsupported_validation_option|
      describe ":#{unsupported_validation_option}" do
        include "DoesNotWorkWith#{unsupported_validation_option.to_s.camelize}Option".constantize
      end
    end

    %i(if on strict unless message).each do |supported_validation_option|
      describe ":#{supported_validation_option}" do
        include "WorksWith#{supported_validation_option.to_s.camelize}Option".constantize
      end
    end
  end
end
