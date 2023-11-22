# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::ContentTypeValidator do
  include ValidatorHelpers

  let(:validator_test_class) { ContentType::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
