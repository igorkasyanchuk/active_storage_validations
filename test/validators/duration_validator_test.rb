# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/checks_validator_validity'
require 'validators/shared_examples/is_performance_optimized'
require 'validators/shared_examples/works_with_all_rails_common_validation_options'

describe ActiveStorageValidations::DurationValidator do
  include ValidatorHelpers

  let(:validator_test_class) { Duration::Validator }
  let(:params) { {} }

  describe '#check_validity!' do
    include ChecksValidatorValidity
  end

  describe 'Validator checks' do
    let(:model) { validator_test_class::Check.new(params) }

    describe ':less_than' do
      # validates :less_than, duration: { less_than: 2.seconds }
      # validates :less_than_proc, duration: { less_than: -> (record) { 2.seconds } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower duration than the duration specified in the model validations' do
            subject { model.less_than.attach(audio_1s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact duration specified in the model validations' do
            subject { model.less_than.attach(audio_2s) and model }

            let(:error_options) do
              {
                duration: '2 seconds',
                filename: 'audio_2s',
                min: nil,
                max: '2 seconds'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with a higher duration than the duration specified in the model validations' do
            subject { model.less_than.attach(audio_5s) and model }

            let(:error_options) do
              {
                duration: '5 seconds',
                filename: 'audio_5s',
                min: nil,
                max: '2 seconds'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_less_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ':less_than_or_equal_to' do
      # validates :less_than_or_equal_to, duration: { less_than_or_equal_to: 2.seconds }
      # validates :less_than_or_equal_to_proc, duration: { less_than_or_equal_to: -> (record) { 2.seconds } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower duration than the duration specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(audio_1s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact duration specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(audio_2s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher duration than the duration specified in the model validations' do
            subject { model.less_than_or_equal_to.attach(audio_5s) and model }

            let(:error_options) do
              {
                duration: '5 seconds',
                filename: 'audio_5s',
                min: nil,
                max: '2 seconds'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_less_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ':greater_than' do
      # validates :greater_than, duration: { greater_than: 7.seconds }
      # validates :greater_than_proc, duration: { greater_than: -> (record) { 7.seconds } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower duration than the duration specified in the model validations' do
            subject { model.greater_than.attach(audio_1s) and model }

            let(:error_options) do
              {
                duration: '1 second',
                filename: 'audio',
                min: '7 seconds',
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact duration specified in the model validations' do
            subject { model.greater_than.attach(audio_7s) and model }

            let(:error_options) do
              {
                duration: '7 seconds',
                filename: 'audio_7s',
                min: '7 seconds',
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_greater_than", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with a higher duration than the duration specified in the model validations' do
            subject { model.greater_than.attach(audio_10s) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ':greater_than_or_equal_to' do
      # validates :greater_than_or_equal_to, duration: { greater_than_or_equal_to: 7.seconds }
      # validates :greater_than_or_equal_to_proc, duration: { greater_than_or_equal_to: -> (record) { 7.seconds } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower duration than the duration specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(audio_1s) and model }

            let(:error_options) do
              {
                duration: '1 second',
                filename: 'audio',
                min: '7 seconds',
                max: nil
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_greater_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact duration specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(audio_7s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher duration than the duration specified in the model validations' do
            subject { model.greater_than_or_equal_to.attach(audio_10s) and model }

            it { is_expected_to_be_valid }
          end
        end
      end
    end

    describe ':between' do
      # validates :between, duration: { between: 2.seconds..7.seconds }
      # validates :between_proc, duration: { between: -> (record) { 2.seconds..7.seconds } }
      %w(value proc).each do |value_type|
        describe "#{value_type} validator" do
          describe 'when provided with a lower duration than the duration specified in the model validations' do
            subject { model.between.attach(audio_1s) and model }

            let(:error_options) do
              {
                duration: '1 second',
                filename: 'audio',
                min: '2 seconds',
                max: '7 seconds'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_between", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          describe 'when provided with the exact lower duration specified in the model validations' do
            subject { model.between.attach(audio_2s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a duration between the durations specified in the model validations' do
            subject { model.between.attach(audio_5s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with the exact higher duration specified in the model validations' do
            subject { model.between.attach(audio_7s) and model }

            it { is_expected_to_be_valid }
          end

          describe 'when provided with a higher duration than the duration specified in the model validations' do
            subject { model.between.attach(audio_10s) and model }

            let(:error_options) do
              {
                duration: '10 seconds',
                filename: 'audio_10s',
                min: '2 seconds',
                max: '7 seconds'
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("duration_not_between", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end
  end

  describe 'Blob Metadata' do
    let(:attachable) do
      {
        io: File.open(Rails.root.join('public', 'audio.mp3')),
        filename: 'audio.mp3',
        content_type: 'audio/mp3'
      }
    end

    include IsPerformanceOptimized
  end

  describe 'Rails options' do
    include WorksWithAllRailsCommonValidationOptions
  end
end
