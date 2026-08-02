# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::AttachedValidator do
  let(:validator_test_class) { Attached::Validator }
  let(:params) { {} }

  # rubocop:disable RSpec/EmptyExampleGroup -- covered by Rails options shared examples
  describe "#check_validity!" do
    # Checked by Rails options tests
  end
  # rubocop:enable RSpec/EmptyExampleGroup

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    context "when provided with a file" do
      # validates :has_to_be_attached, attached: true
      subject(:record) { model.has_to_be_attached.attach(image_1920x1080_file) and model }

      it { is_expected_to_be_valid }
    end

    context "when not provided with a file" do
      # validates :has_to_be_attached, attached: true
      subject(:record) { model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("blank", with_locales: [ "en" ], error_options: {}) }
    end

    context "when provided with a file that is marked for destruction" do
      # validates :has_to_be_attached, attached: true
      subject(:record) { model.has_to_be_attached.attach(image_1920x1080_file) and model.has_to_be_attached.mark_for_destruction and model }

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("blank", with_locales: [ "en" ], error_options: {}) }
    end
  end

  describe "Rails options" do
    %i[allow_nil allow_blank].each do |unsupported_validation_option|
      describe ":#{unsupported_validation_option}" do
        it_behaves_like "does not work with #{unsupported_validation_option} option"
      end
    end

    %i[if on strict unless message].each do |supported_validation_option|
      describe ":#{supported_validation_option}" do
        it_behaves_like "works with #{supported_validation_option} option"
      end
    end
  end
end
