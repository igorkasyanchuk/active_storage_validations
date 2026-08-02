# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ProcessableFileValidator do
  let(:validator_test_class) { ProcessableFile::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"


    %w[image video audio].each do |media_type|
      context "when provided with a #{media_type} that is processable" do
        # validates :has_to_be_processable, processable_file: true
        subject(:record) { model.has_to_be_processable.attach(processable_file) and model }

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

    context "when provided with a file that is not processable" do
      # validates :has_to_be_processable, processable_file: true
      subject(:record) { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

      let(:error_options) do
        {
          filename: "404.png"
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("file_not_processable", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }
    end

    context "when provided with a StringIO that is an image" do
      # validates :has_to_be_processable, processable_file: true
      subject(:record) { model.has_to_be_processable.attach(image_string_io) and model }

      it { is_expected_to_be_valid }
    end

    describe "when the attached file is missing from storage" do
      let(:attribute) { :has_to_be_processable }
      let(:file_for_attachment_missing) { image_150x150_file }

      it_behaves_like "reports attachment_missing"
    end

    context "when using Vips with untrusted loaders blocked", image_processor: :vips do
      # Rails 7.2.3.2+ / 8.0.5.1+ / 8.1.3.1+ call Vips.block_untrusted(true), so
      # analysis of formats with untrusted loaders returns empty metadata by design.
      # https://github.com/rails/rails/security/advisories/GHSA-xr9x-r78c-5hrm
      let(:vips_block_state) { {} }

      before do
        begin
          require "vips"
        rescue LoadError
          skip "requires ruby-vips"
        end

        skip "requires Vips.block_untrusted (ruby-vips >= 2.2.1)" unless Vips.respond_to?(:block_untrusted)

        described_class.reset_vips_untrusted_operations_blocked_cache!
        vips_block_state[:was_blocked] = described_class.vips_untrusted_operations_blocked?
        described_class.reset_vips_untrusted_operations_blocked_cache!
        Vips.block_untrusted(true)
        described_class.reset_vips_untrusted_operations_blocked_cache!
      end

      after do
        next unless vips_block_state.key?(:was_blocked)
        next unless defined?(Vips) && Vips.respond_to?(:block_untrusted)

        Vips.block_untrusted(!!vips_block_state[:was_blocked])
        described_class.reset_vips_untrusted_operations_blocked_cache!
      end

      context "when provided with an SVG" do
        # validates :has_to_be_processable, processable_file: true
        subject(:record) { model.has_to_be_processable.attach(svg_file) and model }

        it { is_expected_to_be_valid }
      end

      context "when provided with a BMP" do
        # validates :has_to_be_processable, processable_file: true
        subject(:record) { model.has_to_be_processable.attach(bmp_file) and model }

        it { is_expected_to_be_valid }
      end

      context "when provided with a file that is not processable" do
        # validates :has_to_be_processable, processable_file: true
        subject(:record) { model.has_to_be_processable.attach(tar_file_with_image_content_type) and model }

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

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
