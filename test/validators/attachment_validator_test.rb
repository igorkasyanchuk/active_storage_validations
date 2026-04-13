# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/asv_errorable"
require "validators/shared_examples/optimized_with_blob_metadata"
require "validators/shared_examples/optimized_with_validate_attached"
require "validators/shared_examples/works_fine_with_attachables"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::AttachmentValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Attachment::Validator }
  let(:params) { {} }

  describe "ASVErrorable shared behavior" do
    include ASVErrorable
  end

  describe "#check_validity!" do
    describe "#ensure_at_least_one_validator_option" do
      describe "when the validator does not have checks" do
        subject { validator_test_class::CheckValidityNoCheck.new(params) }

        let(:error_message_no_check) do
          "You must pass validator options (:size, :dimension, ...) to the `validate_attached` method"
        end

        it "raises an error at model initialization" do
          is_expected_to_raise_error(ArgumentError, error_message_no_check)
        end
      end
    end

    describe "#ensure_size_validator_present_if_heavyweight_validator_requested" do
      describe "when the validator has a heavyweight validator but no size / total_size validator" do
        subject { validator_test_class::CheckValidityHeavyweightValidatorPresence.new(params) }

        let(:error_message_size_validator_present_if_heavyweight_validator_requested) do
          "Using `validate_attached` with heavyweight validators (aspect_ratio) requires a :size or :total_size option."
        end

        it "raises an error at model initialization" do
          is_expected_to_raise_error(ArgumentError, error_message_size_validator_present_if_heavyweight_validator_requested)
        end
      end
    end
  end

  # describe "Validator checks" do
  #   # include WorksFineWithAttachables
  # end

  # describe "Blob Metadata" do
  #   let(:attachable) do
  #     {
  #       io: File.open(Rails.root.join("public", "image_150x150.png")),
  #       filename: "image_150x150.png",
  #       content_type: "image/png"
  #     }
  #   end

  #   include OptimizedWithBlobMetadata
  # end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
