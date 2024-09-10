# frozen_string_literal: true

require "test_helper"
require "open-uri"

describe ActiveStorageValidations::Metadata do
  include ValidatorHelpers

  let(:instance) { Metadata.new }

  describe "Vips" do
    # Uncomment these lines in development, or launch test with ENV['IMAGE_PROCESSOR'] = :vips
    # before do
    #   @original_variant_processor = Rails.application.config.active_storage.variant_processor
    #   Rails.application.config.active_storage.variant_processor = :vips
    # end

    # after do
    #   Rails.application.config.active_storage.variant_processor = @original_variant_processor
    # end

    describe "OpenURI" do
      before do
        stub_request(:get, url)
          .to_return(body: File.open(Rails.root.join('public', fetched_file)), status: 200)
      end

      subject { instance.large_image.attach(io: remote_image, filename: fetched_file, content_type: "image/png") and instance }

      let(:url) { "https://example_image.jpg" }
      let(:remote_image) { URI.parse(url).open }

      describe "Opening small images (< 10ko) resulting in OpenUri returning a StringIO" do
        let(:fetched_file) { 'file_3ko.png' }

        it { is_expected_to_be_valid }
      end

      describe "Opening large images (>= 10ko) resulting in OpenUri returning a Tempfile" do
        let(:fetched_file) { 'file_10ko.png' }

        it { is_expected_to_be_valid }
      end
    end
  end
end
