# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::AspectRatioValidator do
  let(:validator_test_class) { AspectRatio::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "#check_validity!" do
    it_behaves_like "checks validator validity"

    describe "aspect ratio validity" do
      context "when the passed option is an invalid" do
        let(:error_message) do
          <<~ERROR_MESSAGE
            You must pass a valid aspect ratio to the validator (got #{invalid_value.inspect})
            It should either be a named aspect ratio (#{ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.join(', ')})
            Or an aspect ratio like 'is_16_9' (matching /#{ActiveStorageValidations::AspectRatioValidator::ASPECT_RATIO_REGEX.source}/)
          ERROR_MESSAGE
        end

        describe "named aspect ratio" do
          subject(:model) { validator_test_class::CheckValidityInvalidNamedArgument.new(params) }

          let(:invalid_value) { :television }

          it "raises an error at model initialization" do
            expect { model }.to raise_error(ArgumentError, error_message)
          end
        end

        describe "is_x_y aspect ratio" do
          subject(:model) { validator_test_class::CheckValidityInvalidIsXyArgument.new(params) }

          let(:invalid_value) { :is_0_1 }

          it "raises an error at model initialization" do
            expect { model }.to raise_error(ArgumentError, error_message)
          end
        end
      end

      context "when the passed option is a Proc" do
        subject(:model) { validator_test_class::CheckValidityProcOption.new(params) }

        it "does not perform a check, and therefore is valid" do
          expect { model }.not_to raise_error
        end

        # validates :invalid, aspect_ratio: ->(record) { :invalid }
        it "checks the aspect ratios returned by the Proc at validation time" do
          model.invalid.attach(image_150x150_file)

          expect { model.valid? }.to raise_error(ArgumentError, /You must pass a valid aspect ratio to the validator \(got :invalid\)/)
        end

        # validates :nested_invalid, aspect_ratio: { in: [ :square, ->(record) { "16:9" } ] }
        it "checks the aspect ratios returned by a Proc nested in the list at validation time" do
          model.nested_invalid.attach(image_150x150_file)

          expect { model.valid? }.to raise_error(ArgumentError, /You must pass a valid aspect ratio to the validator \(got "16:9"\)/)
        end

        # validates :nested_list, aspect_ratio: { in: [ :portrait, ->(record) { [ :square, :landscape ] } ] }
        it "authorizes the aspect ratios of a list returned by a nested Proc" do
          model.nested_list.attach(image_150x150_file)

          expect(model).to be_valid
        end
      end

      context "when the authorized list is empty" do
        subject(:validator) { described_class.new(attributes: [ :file ], with: []) }

        it "raises an error at validator initialization" do
          expect { validator }.to raise_error(ArgumentError, "You must pass at least one aspect ratio to the validator")
        end
      end
    end
  end

  describe "ASPECT_RATIO_REGEX" do
    let(:aspect_ratio_regex) { ActiveStorageValidations::AspectRatioValidator::ASPECT_RATIO_REGEX }
    let(:accepted_is_x_y_strings) do
      %w[
        is_16_9
        is_4_5
        is_69_25
        is_143_100
      ]
    end
    let(:not_accepted_is_x_y_strings) do
      %w[
        is__1
        is_5_
        is_square
        is_0_1
        is_1_0
        is_0_0
        is_01_2
        is_16_9_extra
        not_is_16_9
        is_16_9x
      ]
    end

    it "accepts ratios like 'is_16_9'" do
      expect(accepted_is_x_y_strings).to all(match(aspect_ratio_regex))
      expect(not_accepted_is_x_y_strings).to all(satisfy { |value| !value.match?(aspect_ratio_regex) })
    end

    it "rejects ratios with surrounding characters at boot" do
      expect { described_class.new(attributes: [ :file ], with: :is_16_9_extra) }
        .to raise_error(ArgumentError, /You must pass a valid aspect ratio to the validator/)
    end
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"


    describe ":with" do
      # validates :with_named_square, aspect_ratio: :square
      # validates :with_named_portrait, aspect_ratio: :portrait
      # validates :with_named_landscape, aspect_ratio: :landscape
      # validates :with_named_square_proc, aspect_ratio: -> (record) { :square }
      # validates :with_named_portrait_proc, aspect_ratio: -> (record) { :portrait }
      # validates :with_named_landscape_proc, aspect_ratio: -> (record) { :landscape }
      %w[value proc].each do |value_type|
        describe "named aspect_ratio" do
          %i[square portrait landscape].each do |named_aspect_ratio|
            describe ":#{named_aspect_ratio}" do
              let(:attribute) { :"with_#{named_aspect_ratio}#{'_proc' if value_type == 'proc'}" }

              context "when provided with an allowed aspect_ratio file" do
                subject(:record) { model.public_send(attribute).attach(allowed_file) and model }

                let(:allowed_file) do
                  case named_aspect_ratio
                  when :square then square_image_file
                  when :portrait then portrait_image_file
                  when :landscape then landscape_image_file
                  end
                end

                it { is_expected_to_be_valid }
              end

              context "when provided with a not allowed aspect_ratio file" do
                subject(:record) { model.public_send(attribute).attach(not_allowed_file) and model }

                let(:not_allowed_file) do
                  case named_aspect_ratio
                  when :square then portrait_image_file
                  when :portrait then landscape_image_file
                  when :landscape then square_image_file
                  end
                end
                let(:width) do
                  case named_aspect_ratio
                  when :square then 600
                  when :portrait then 700
                  when :landscape then 150
                  end
                end
                let(:height) do
                  case named_aspect_ratio
                  when :square then 800
                  when :portrait then 500
                  when :landscape then 150
                  end
                end
                let(:error_options) do
                  {
                    authorized_aspect_ratios: named_aspect_ratio.to_s,
                    width: width,
                    height: height,
                    filename: not_allowed_file[:filename]
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("aspect_ratio_not_#{named_aspect_ratio}", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end

        describe "regex aspect_ratio" do
          let(:attribute) { :"with_regex#{'_proc' if value_type == 'proc'}" }

          context "when provided with an allowed aspect_ratio file" do
            subject(:record) { model.public_send(attribute).attach(allowed_file) and model }

            let(:allowed_file) { is_16_9_image_file }

            it { is_expected_to_be_valid }
          end

          context "when provided with a not allowed aspect_ratio file" do
            subject(:record) { model.public_send(attribute).attach(not_allowed_file) and model }

            let(:not_allowed_file) { is_4_3_image_file }
            let(:error_options) do
              {
                authorized_aspect_ratios: "16:9",
                width: 1200,
                height: 900,
                filename: not_allowed_file[:filename]
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("aspect_ratio_not_x_y", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ":in" do
      %w[value proc].each do |value_type|
        describe value_type do
          let(:attribute) { :"in_aspect_ratios#{'_proc' if value_type == 'proc'}" }

          context "when provided with an allowed aspect_ratio file" do
            subject(:record) { model.public_send(attribute).attach(allowed_file) and model }

            let(:allowed_file) { [ square_image_file, portrait_image_file, is_16_9_image_file ].sample }

            it { is_expected_to_be_valid }
          end

          context "when provided with a not allowed aspect_ratio file" do
            subject(:record) { model.public_send(attribute).attach(not_allowed_file) and model }

            let(:not_allowed_file) { is_4_3_image_file }

            let(:error_options) do
              {
                authorized_aspect_ratios: "square, portrait, 16:9",
                width: 1200,
                height: 900,
                filename: not_allowed_file[:filename]
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("aspect_ratio_invalid", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe "custom ratio pixel tolerance" do
      let(:attribute) { :with_regex }

      # rubocop:disable RSpec/AnyInstance -- validator instantiated by Active Model
      def stub_dimensions(width, height)
        allow_any_instance_of(described_class).to receive(:metadata_for).and_return({ width: width, height: height })
      end
      # rubocop:enable RSpec/AnyInstance

      context "when the image is 1 pixel off 16:9 (1366x768)" do
        subject(:record) { model.public_send(attribute).attach(square_image_file) and model }

        before { stub_dimensions(1366, 768) }

        it { is_expected_to_be_valid }
      end

      context "when the image is 1 pixel off 16:9 (854x480)" do
        subject(:record) { model.public_send(attribute).attach(square_image_file) and model }

        before { stub_dimensions(854, 480) }

        it { is_expected_to_be_valid }
      end

      context "when the image is 2 pixels off 16:9 (1920x1082)" do
        subject(:record) { model.public_send(attribute).attach(square_image_file) and model }

        before { stub_dimensions(1920, 1082) }

        let(:error_options) do
          {
            authorized_aspect_ratios: "16:9",
            width: 1920,
            height: 1082,
            filename: square_image_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("aspect_ratio_not_x_y", error_options: error_options) }
      end
    end

    context "when the Proc returns an empty list" do
      subject(:record) { model.public_send(attribute).attach(square_image_file) and model }

      let(:attribute) { :with_empty_proc }
      let(:error_options) do
        {
          authorized_aspect_ratios: "",
          width: 150,
          height: 150,
          filename: square_image_file[:filename]
        }
      end

      it { is_expected_not_to_be_valid }
      it { is_expected_to_include_error_message("aspect_ratio_invalid", error_options: error_options) }
      it { is_expected_to_have_error_options(error_options) }
    end

    describe "Edge cases" do
      context "when the passed file is not a valid media" do
        subject(:record) { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the attached file is missing from storage" do
        let(:attribute) { :with_square }
        let(:file_for_attachment_missing) { image_150x150_file }

        it_behaves_like "reports attachment_missing"
      end

      context "when the passed file is a pdf" do
        describe "valid pdf" do
          subject(:record) { model.public_send(attribute).attach(pdf_150x150_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              filename: pdf_150x150_file[:filename]
            }
          end

          it { is_expected_to_be_valid }
        end

        describe "invalid pdf" do
          subject(:record) { model.public_send(attribute).attach(pdf_200x300_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              authorized_aspect_ratios: "square",
              width: 200,
              height: 300,
              filename: pdf_200x300_file[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("aspect_ratio_not_square", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "image_150x150.png")),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
