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

  describe 'Validator checks' do
    let(:model) { validator_test_class::Check.new(params) }

    describe 'when provided with a file' do
      # validates :has_to_be_attached, attached: true
      subject { model.has_to_be_attached.attach(image_1920x1080_file) and model }

      it { is_expected_to_be_valid }
    end

    describe 'when not provided with a file' do
      # validates :has_to_be_attached, attached: true
      subject { model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("blank", error_options: {}) }
    end

    describe 'when provided with a file that is marked for destruction' do
      # validates :has_to_be_attached, attached: true
      subject { model.has_to_be_attached.attach(image_1920x1080_file) and model.has_to_be_attached.mark_for_destruction and model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_have_error_message("blank", error_options: {}) }
    end
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
