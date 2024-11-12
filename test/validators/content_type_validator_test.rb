# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/works_fine_with_attachables'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::ContentTypeValidator do
  include ValidatorHelpers

  let(:validator_test_class) { ContentType::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity

    describe 'content type validity' do
      describe 'when the passed option is an invalid content type' do
        subject { validator_test_class::CheckValidityInvalidContentType.new(params) }

        let(:error_message) do
          <<~ERROR_MESSAGE
            You must pass valid content types to the validator
            '#{invalid_content_type}' is not found in Marcel::TYPE_EXTS
          ERROR_MESSAGE
        end
        let(:invalid_content_type) { "xxx/invalid" }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end

      describe 'when the passed option is an invalid extension' do
        subject { validator_test_class::CheckValidityInvalidExtension.new(params) }

        let(:error_message) do
          <<~ERROR_MESSAGE
            You must pass valid content types extensions to the validator
            '#{invalid_extension.to_s}' is not found in Marcel::EXTENSIONS
          ERROR_MESSAGE
        end
        let(:invalid_extension) { :invalid }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end

      describe 'when the passed option is a Regex' do
        subject { validator_test_class::CheckValidityRegexOption.new(params) }

        it 'does not perform a check, and therefore is valid' do
          assert_nothing_raised { subject }
        end
      end

      describe 'when the passed option is a Proc' do
        subject { validator_test_class::CheckValidityProcOption.new(params) }

        it 'does not perform a check, and therefore is valid' do
          assert_nothing_raised { subject }
        end
      end
    end
  end

  describe 'Validator checks' do
    include WorksFineWithAttachables

    let(:model) { validator_test_class::Check.new(params) }

    describe "#extension_matches_content_type?" do
      describe "when the attachable content_type and extension cannot match (e.g. 'text/plain' and .png)" do
        subject { model.public_send(attribute).attach(file_with_issue) and model }

        let(:attribute) { :extension_content_type_mismatch }
        let(:file_with_issue) { extension_content_type_mismatch_file }
        let(:error_options) do
          {
            authorized_types: "PNG",
            content_type: file_with_issue[:content_type],
            filename: file_with_issue[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_have_error_message("content_type_invalid", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the file has 2 extensions (e.g. hello.docx.pdf)" do
        describe "and we only allow the first extension content_type (e.g. 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' (docx))" do
          subject { model.public_send(attribute).attach(docx_file_with_two_extensions) and model }

          let(:attribute) { :extension_two_extensions_docx }
          let(:docx_file_with_two_extensions) do
            docx_file.tap do |file|
              file[:filename] += ".pdf"
            end
          end
          let(:error_options) do
            {
              authorized_types: "DOCX",
              content_type: docx_file_with_two_extensions[:content_type],
              filename: docx_file_with_two_extensions[:filename]
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_message("content_type_invalid", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        describe "and we allow the last extension content_type (e.g. 'application/pdf')" do
          subject { model.public_send(attribute).attach(docx_file_with_two_extensions) and model }

          let(:attribute) { :extension_two_extensions_pdf }
          let(:docx_file_with_two_extensions) do
            docx_file.tap do |file|
              file[:filename] += ".pdf"
              file[:content_type] = "application/pdf"
            end
          end

          it { is_expected_to_be_valid }
        end
      end

      describe "when the extension is in uppercase" do
        subject { model.public_send(attribute).attach(pdf_file_with_extension_in_uppercase) and model }

        let(:attribute) { :extension_upcase_extension }
        let(:pdf_file_with_extension_in_uppercase) do
          pdf_file.tap do |file|
            file[:filename][".pdf"] = ".PDF"
          end
        end

        it { is_expected_to_be_valid }
      end

      describe "when the extension is missing" do
        subject { model.public_send(attribute).attach(pdf_file_without_extension) and model }

        let(:attribute) { :extension_missing_extension }
        let(:pdf_file_without_extension) do
          pdf_file.tap do |file|
            file[:filename][".pdf"] = ""
          end
        end
        let(:error_options) do
          {
            authorized_types: "PDF",
            content_type: pdf_file_without_extension[:content_type],
            filename: pdf_file_without_extension[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_have_error_message("content_type_invalid", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end
    end

    describe ":with" do
      # validates :with_string, content_type: 'png'
      # validates :with_symbol, content_type: :png
      # validates :with_regex, content_type: /\Aimage\/.*\z/
      # validates :with_string_proc, content_type: -> (record) { 'png' }
      # validates :with_symbol_proc, content_type: -> (record) { :png }
      # validates :with_regex_proc, content_type: -> (record) { /\Aimage\/.*\z/ }
      %w(value proc).each do |value_type|
        describe value_type do
          %w(string symbol regex).each do |type|
            describe type do
              let(:attribute) { :"with_#{type}#{'_proc' if value_type == 'proc'}" }

              describe 'when provided with an allowed type file' do
                subject { model.public_send(attribute).attach(allowed_file) and model }

                let(:allowed_file) { png_file }

                it { is_expected_to_be_valid }
              end

              describe 'when provided with a not allowed type file' do
                subject { model.public_send(attribute).attach(not_allowed_file) and model }

                let(:not_allowed_file) { numbers_file }
                let(:authorized_types) { type == 'regex' ? '\\Aimage/.*\\z' : 'PNG' }
                let(:error_options) do
                  {
                    authorized_types: authorized_types,
                    content_type: not_allowed_file[:content_type],
                    filename: not_allowed_file[:filename]
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_have_error_message("content_type_invalid", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end
      end
    end

    describe ":in" do
      # validates :in_strings, content_type: ['png', 'gif']
      # validates :in_symbols, content_type: [:png, :gif]
      # validates :in_regexes, content_type: [/\Aimage\/.*\z/, /\Afile\/.*\z/]
      # validates :in_strings_proc, content_type: -> (record) { ['png', 'gif'] }
      # validates :in_symbols_proc, content_type: -> (record) { [:png, :gif] }
      # validates :in_regexes_proc, content_type: -> (record) { [/\Aimage\/.*\z/, /\Afile\/.*\z/] }
      %w(value proc).each do |value_type|
        describe value_type do
          %w(string symbol regex).each do |type|
            describe type do
              let(:attribute) { :"in_#{type.pluralize}#{'_proc' if value_type == 'proc'}" }

              describe 'when provided with an allowed type file' do
                subject { model.public_send(attribute).attach(allowed_file) and model }

                let(:allowed_file) { [png_file, gif_file].sample }

                it { is_expected_to_be_valid }
              end

              describe 'when provided with a not allowed type file' do
                subject { model.public_send(attribute).attach(not_allowed_file) and model }

                let(:not_allowed_file) { numbers_file }
                let(:authorized_types) { type == 'regex' ? '\\Aimage/.*\\z, \\Afile/.*\\z' : 'PNG, GIF' }
                let(:error_options) do
                  {
                    authorized_types: authorized_types,
                    content_type: not_allowed_file[:content_type],
                    filename: not_allowed_file[:filename]
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_have_error_message("content_type_invalid", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end
      end
    end

    describe "Edge cases" do
      describe "when using a file that has a content_type with a parameter (e.g. 'application/x-rar-compressed;version=5')" do
        subject { model.public_send(attribute).attach(file_having_content_type_with_parameter) and model }

        let(:attribute) { :content_type_with_parameter }
        let(:file_having_content_type_with_parameter) { rar_file } # 'application/x-rar-compressed;version=5'

        it { is_expected_to_be_valid }
      end
    end

    describe ':spoofing_protection' do
      # Further testing performed by content_type_spoof_detector_test.rb

      describe "when the protection is enabled (spoofing_protection: true option)" do
        let(:attribute) { :spoofing_protection }

        describe "when the file is spoofed" do
          subject { model.public_send(attribute).attach(spoofed_file) and model }

          let(:spoofed_file) { spoofed_jpeg }

          it { is_expected_not_to_be_valid }
        end
      end

      describe "when the protection is disabled (default / spoofing_protection: false option)" do
        let(:attribute) { :no_spoofing_protection }

        describe "when the file is spoofed" do
          subject { model.public_send(attribute).attach(spoofed_file) and model }

          let(:spoofed_file) { spoofed_jpeg }

          it { is_expected_to_be_valid }
        end
      end
    end
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
