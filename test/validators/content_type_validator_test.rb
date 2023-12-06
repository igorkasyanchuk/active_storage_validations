# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
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
            '#{invalid_content_type.to_s}' is not find in Marcel::EXTENSIONS mimes
          ERROR_MESSAGE
        end
        let(:invalid_content_type) { :invalid }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
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
    let(:model) { validator_test_class::Check.new(params) }

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
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
