# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/does_not_work_with_allow_blank_option"
require "validators/shared_examples/does_not_work_with_allow_nil_option"
require "validators/shared_examples/works_with_if_option"
require "validators/shared_examples/works_with_message_option"
require "validators/shared_examples/works_with_on_option"
require "validators/shared_examples/works_with_unless_option"
require "validators/shared_examples/works_with_strict_option"

describe ActiveStorageValidations::AttachedValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Attached::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    describe "#ensure_options_validity" do
      describe "when the validator has an invalid check" do
        subject { validator_test_class::CheckValidityInvalidCheck.new(params) }

        let(:error_message_invalid_check) do
          "You must pass either `true` or `{ with: true/Proc }`"
        end

        it "raises an error at model initialization" do
          is_expected_to_raise_error(ArgumentError, error_message_invalid_check)
        end
      end
    end

    describe "#ensure_no_allow_nil_or_blank_options" do
      describe "when the validator has an allow_nil option" do
        subject { validator_test_class::CheckValidityAllowNilOption.new(params) }

        let(:error_message_allow_nil) do
          "You cannot pass the :allow_nil option to the #{validator_test_class.name.delete('::').underscore.split('_').join(' ')}"
        end

        it "raises an error at model initialization" do
          is_expected_to_raise_error(ArgumentError, error_message_allow_nil)
        end
      end

      describe "when the validator has an allow_blank option" do
        subject { validator_test_class::CheckValidityAllowBlankOption.new(params) }

        let(:error_message_allow_blank) do
          "You cannot pass the :allow_blank option to the #{validator_test_class.name.delete('::').underscore.split('_').join(' ')}"
        end

        it "raises an error at model initialization" do
          is_expected_to_raise_error(ArgumentError, error_message_allow_blank)
        end
      end
    end
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    describe "when provided with a file" do
      # validates :has_to_be_attached, attached: true
      subject { model.has_to_be_attached.attach(image_1920x1080_file) and model }

      it { is_expected_to_be_valid }
    end

    describe "when not provided with a file" do
      # validates :has_to_be_attached, attached: true
      subject { model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("blank", with_locales: [ "en" ], error_options: {}) }
    end

    describe "when provided with a file that is marked for destruction" do
      # validates :has_to_be_attached, attached: true
      subject { model.has_to_be_attached.attach(image_1920x1080_file) and model.has_to_be_attached.mark_for_destruction and model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("blank", with_locales: [ "en" ], error_options: {}) }
    end
  end

  describe "Rails options" do
    %i[allow_nil allow_blank].each do |unsupported_validation_option|
      describe ":#{unsupported_validation_option}" do
        include "DoesNotWorkWith#{unsupported_validation_option.to_s.camelize}Option".constantize
      end
    end

    %i[if on strict unless message].each do |supported_validation_option|
      describe ":#{supported_validation_option}" do
        include "WorksWith#{supported_validation_option.to_s.camelize}Option".constantize
      end
    end
  end
end
