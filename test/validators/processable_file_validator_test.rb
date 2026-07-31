# frozen_string_literal: true

require "test_helper"
require "validators/shared_examples/asv_attachable"
require "validators/shared_examples/asv_errorable"
require "validators/shared_examples/is_performance_optimized"
require "validators/shared_examples/works_fine_with_attachables"
require "validators/shared_examples/works_with_all_rails_common_validation_options"

describe ActiveStorageValidations::ProcessableFileValidator do
  include ValidatorHelpers

  let(:validator_test_class) { ProcessableFile::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    include ASVAttachable
  end

  describe "#initialize_error_options" do
    include ASVErrorable
  end

  describe "Validator checks" do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    %w[image video audio].each do |media_type|
      describe "when provided with a #{media_type} that is processable" do
        # validates :has_to_be_processable, processable_file: true
        subject { model.has_to_be_processable.attach(processable_file) and model }

        let(:processable_file) do
          case media_type
          when "image" then image_1920x1080_file
          when "video" then video_file
          when "audio" then audio_file
          end
        end

        it { is_expected_to_be_valid }
      end
    end

    describe "when provided with a file that is not processable" do
      # validates :has_to_be_processable, processable_file: true
      subject { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

      let(:error_options) do
        {
          filename: "404.png"
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("file_not_processable", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }
    end

    describe "when provided with a StringIO that is an image" do
      # validates :has_to_be_processable, processable_file: true
      subject { model.has_to_be_processable.attach(image_string_io) and model }

      it { is_expected_to_be_valid }
    end

    describe "when using Vips with untrusted loaders blocked" do
      # Rails 7.2.3.2+ / 8.0.5.1+ / 8.1.3.1+ call Vips.block_untrusted(true), so
      # analysis of formats with untrusted loaders returns empty metadata by design.
      # https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm
      before do
        skip "requires the Vips image processor" unless ActiveStorage.variant_processor == :vips

        begin
          require "vips"
        rescue LoadError
          skip "requires ruby-vips"
        end

        skip "requires Vips.block_untrusted (ruby-vips >= 2.2.1)" unless Vips.respond_to?(:block_untrusted)

        ActiveStorageValidations::ProcessableFileValidator.reset_vips_untrusted_operations_blocked_cache!
        @untrusted_was_blocked = ActiveStorageValidations::ProcessableFileValidator.vips_untrusted_operations_blocked?
        ActiveStorageValidations::ProcessableFileValidator.reset_vips_untrusted_operations_blocked_cache!
        Vips.block_untrusted(true)
        ActiveStorageValidations::ProcessableFileValidator.reset_vips_untrusted_operations_blocked_cache!
      end

      after do
        if defined?(Vips) && Vips.respond_to?(:block_untrusted)
          Vips.block_untrusted(!!@untrusted_was_blocked)
          ActiveStorageValidations::ProcessableFileValidator.reset_vips_untrusted_operations_blocked_cache!
        end
      end

      describe "when provided with an SVG" do
        # validates :has_to_be_processable, processable_file: true
        subject { model.has_to_be_processable.attach(svg_file) and model }

        it { is_expected_to_be_valid }
      end

      describe "when provided with a BMP" do
        # validates :has_to_be_processable, processable_file: true
        subject { model.has_to_be_processable.attach(bmp_file) and model }

        it { is_expected_to_be_valid }
      end

      describe "when provided with a file that is not processable" do
        # validates :has_to_be_processable, processable_file: true
        subject { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

        let(:error_options) do
          {
            filename: "404.png"
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("file_not_processable", error_options: error_options) }
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: File.open(Rails.root.join("public", "audio.mp3")),
        filename: "audio.mp3",
        content_type: "audio/mp3"
      }
    end

    include IsPerformanceOptimized
  end

  describe "Rails options" do
    include WorksWithAllRailsCommonValidationOptions
  end
end
