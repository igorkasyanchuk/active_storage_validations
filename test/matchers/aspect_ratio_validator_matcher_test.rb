# frozen_string_literal: true

require 'test_helper'
require 'matchers/shared_examples/checks_if_is_a_valid_active_storage_attribute'
require 'matchers/shared_examples/checks_if_is_valid'
require 'matchers/shared_examples/has_valid_rspec_message_methods'
require 'matchers/shared_examples/works_with_allow_blank'
require 'matchers/shared_examples/works_with_both_instance_and_class'
require 'matchers/shared_examples/works_with_context'
require 'matchers/shared_examples/works_with_custom_message'

describe ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher do
  include MatcherHelpers

  include ChecksIfIsAValidActiveStorageAttribute
  include ChecksIfIsValid
  include HasValidRspecMessageMethods
  include WorksWithBothInstanceAndClass

  let(:matcher) { ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher.new(model_attribute) }
  let(:klass) { AspectRatio::Matcher }

  describe '#allowing' do
    describe 'one' do
      describe 'named aspect ratio' do
        ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
          describe ":#{aspect_ratio}" do
            let(:model_attribute) { :"allowing_one_#{aspect_ratio}" }
            let(:allowed_aspect_ratio) { aspect_ratio }

            describe 'when provided with the exact named allowed aspect ratio' do
              subject { matcher.allowing(allowed_aspect_ratio) }

              it { is_expected_to_match_for(klass) }
            end

            describe "when provided with a 'is_x_y' aspect ratio" do
              describe 'that fits the named aspect ratio constraint' do
                subject { matcher.allowing(matching_is_x_y_aspect_ratio) }

                let(:matching_is_x_y_aspect_ratio) do
                  case aspect_ratio
                  when :square then :is_2_2
                  when :portrait then :is_4_5
                  when :landscape then :is_16_9
                  end
                end

                it { is_expected_to_match_for(klass) }
              end

              describe 'that does not fit the named aspect ratio constraint' do
                subject { matcher.allowing(not_matching_is_x_y_aspect_ratio) }

                let(:not_matching_is_x_y_aspect_ratio) do
                  case aspect_ratio
                  when :square then :is_16_9
                  when :portrait then :is_2_2
                  when :landscape then :is_4_5
                  end
                end

                it { is_expected_not_to_match_for(klass) }
              end
            end

            describe 'when provided with any aspect ratio but the named allowed aspect ratio' do
              subject { matcher.allowing(any_aspect_ratio) }

              let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS - [aspect_ratio]).sample }

              it { is_expected_not_to_match_for(klass) }
            end

            describe 'when provided with something that is not a valid named aspect ratio' do
              subject { matcher.allowing(not_valid_aspect_ratio) }

              let(:not_valid_aspect_ratio) { :not_valid }

              it { is_expected_not_to_match_for(klass) }
            end
          end
        end
      end

      describe "'is_x_y' aspect ratio" do
        let(:model_attribute) { :allowing_one_is_x_y }

        describe 'when provided with a regex compatible aspect ratio' do
          subject { matcher.allowing(allowed_aspect_ratio) }

          let(:allowed_aspect_ratio) { :is_16_9 }

          it { is_expected_to_match_for(klass) }
        end

        describe 'when provided with something that is not a valid aspect ratio' do
          subject { matcher.allowing(not_valid_aspect_ratio) }

          let(:not_valid_aspect_ratio) { :is_16 }

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end
  end

  describe '#rejecting' do
    describe 'one' do
      describe 'named aspect ratio' do
        ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
          describe ":#{aspect_ratio}" do
            let(:model_attribute) { :"allowing_one_#{aspect_ratio}" }
            let(:allowed_aspect_ratio) { aspect_ratio }

            describe 'when provided with the exact allowed named aspect ratio' do
              subject { matcher.rejecting(allowed_aspect_ratio) }

              it { is_expected_not_to_match_for(klass) }
            end

            describe 'when provided with any aspect ratio but the allowed named aspect ratio' do
              subject { matcher.rejecting(any_aspect_ratio) }

              let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS - [aspect_ratio]).sample }

              it { is_expected_to_match_for(klass) }
            end

            describe 'when provided with something that is not a valid named aspect ratio' do
              subject { matcher.rejecting(not_valid_aspect_ratio) }

              let(:not_valid_aspect_ratio) { 'not_valid' }

              it { is_expected_to_match_for(klass) }
            end
          end
        end
      end

      describe "'is_x_y' aspect ratio" do
        let(:model_attribute) { :allowing_one_is_x_y }

        describe 'when provided with the exact allowed aspect ratio' do
          subject { matcher.rejecting(allowed_aspect_ratio) }

          let(:allowed_aspect_ratio) { :is_16_9 }

          it { is_expected_not_to_match_for(klass) }
        end

        describe 'when provided with any aspect ratio but the allowed aspect ratio' do
          subject { matcher.rejecting(any_aspect_ratio) }

          let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS + [:is_4_5]).sample }

          it { is_expected_to_match_for(klass) }
        end

        describe 'when provided with something that is not a valid aspect ratio' do
          subject { matcher.allowing(not_valid_aspect_ratio) }

          let(:not_valid_aspect_ratio) { 'not_valid' }

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end
  end

  describe 'Combinations' do
    describe '#allowing + #with_message' do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_aspect_ratio) { :portrait }

      describe 'when provided with the exact allowed type' do
        describe 'and when provided with the message specified in the model validations' do
          subject do
            matcher.allowing(allowed_aspect_ratio)
            matcher.with_message('Not authorized aspect ratio.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe '#rejecting + #with_message' do
      let(:model_attribute) { :allowing_one_with_message }
      let(:not_allowed_aspect_ratio) { :square }

      describe 'when provided with a not allowed aspect ratio' do
        describe 'and when provided with the message specified in the model validations' do
          subject do
            matcher.rejecting(not_allowed_aspect_ratio)
            matcher.with_message('Not authorized aspect ratio.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe '#allowing + #rejecting' do
      let(:model_attribute) { :allowing_one_square }
      let(:allowed_aspect_ratio) { :square }
      let(:not_allowed_aspect_ratio) { :portrait }

      describe 'when provided with the exact allowed aspect ratio' do
        describe 'and when provided with a not allowed aspect ratio specified in the model validations' do
          subject do
            matcher.allowing(allowed_aspect_ratio)
            matcher.rejecting(not_allowed_aspect_ratio)
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe '#allowing + #rejecting + #with_message' do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_aspect_ratio) { :portrait }
      let(:not_allowed_aspect_ratio) { :landscape }

      describe 'when provided with the exact allowed aspect ratio' do
        describe 'and when provided with a not allowed aspect ratio' do
          describe 'and when provided with the message specified in the model validations' do
            subject do
              matcher.allowing(allowed_aspect_ratio)
              matcher.rejecting(not_allowed_aspect_ratio)
              matcher.with_message('Not authorized aspect ratio.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end
  end

  describe "#allow_blank" do
    include WorksWithAllowBlank
  end

  describe '#with_message' do
    include WorksWithCustomMessage
  end

  describe "#on" do
    include WorksWithContext
  end
end
