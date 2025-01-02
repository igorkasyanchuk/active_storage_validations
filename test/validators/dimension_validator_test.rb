# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_fine_with_attachables'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::DimensionValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Dimension::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity
  end

  describe 'Validator checks' do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    describe "Edge cases" do
      describe "when the passed file is not a valid media" do
        subject { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_have_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end
    end
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
