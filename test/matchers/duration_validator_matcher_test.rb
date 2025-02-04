# frozen_string_literal: true

require "test_helper"
require "matchers/shared_examples/base_comparison_validator_matcher"
require "matchers/shared_examples/checks_if_is_a_valid_active_storage_attribute"
require "matchers/shared_examples/checks_if_is_valid"
require "matchers/shared_examples/has_custom_matcher"
require "matchers/shared_examples/has_valid_rspec_message_methods"
require "matchers/shared_examples/works_with_allow_blank"
require "matchers/shared_examples/works_with_both_instance_and_class"
require "matchers/shared_examples/works_with_context"
require "matchers/shared_examples/works_with_custom_message"

describe ActiveStorageValidations::Matchers::DurationValidatorMatcher do
  include MatcherHelpers

  include ChecksIfIsAValidActiveStorageAttribute
  include ChecksIfIsValid
  include HasCustomMatcher
  include HasValidRspecMessageMethods
  include WorksWithBothInstanceAndClass

  let(:matcher) { ActiveStorageValidations::Matchers::DurationValidatorMatcher.new(model_attribute) }
  let(:klass) { Duration::Matcher }

  describe "#validate_duration_of" do
    include HasCustomMatcher
  end

  describe "#less_than" do
    let(:matcher_method) { :less_than }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 2.seconds }

    include BaseComparisonValidatorMatcher::OnlyMatchWhenExactValue
  end

  describe "#less_than_or_equal_to" do
    let(:matcher_method) { :less_than_or_equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 2.seconds }

    include BaseComparisonValidatorMatcher::OnlyMatchWhenExactValue
  end

  describe "#greater_than" do
    let(:matcher_method) { :greater_than }
    let(:validator_value) { 7.seconds }

    describe "with has_one_attached" do
      let(:model_attribute) { matcher_method }

      include BaseComparisonValidatorMatcher::OnlyMatchWhenExactValue
    end

    describe "with has_many_attached" do
      let(:model_attribute) { :many_greater_than }

      include BaseComparisonValidatorMatcher::OnlyMatchWhenExactValue
    end
  end

  describe "#greater_than_or_equal_to" do
    let(:matcher_method) { :greater_than_or_equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 7.seconds }

    include BaseComparisonValidatorMatcher::OnlyMatchWhenExactValue
  end

  describe "#between" do
    let(:model_attribute) { :between }

    describe "when provided with the exact durations specified in the model validations" do
      subject { matcher.between 2.seconds..7.seconds }

      it { is_expected_to_match_for(klass) }
    end

    describe "when provided with a higher duration than the duration specified in the model validations" do
      describe "for the highest possible duration" do
        subject { matcher.between 2.seconds..10.seconds }

        it { is_expected_not_to_match_for(klass) }
      end

      describe "for the lowest possible duration" do
        subject { matcher.between 5.seconds..7.seconds }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe "when provided with a lower duration than the duration specified in the model validations" do
      describe "for the highest possible duration" do
        subject { matcher.between 1.seconds..7.seconds }

        it { is_expected_not_to_match_for(klass) }
      end

      describe "for the lowest possible duration" do
        subject { matcher.between 1.seconds..7.seconds }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe "when provided with both lowest and highest possible durations different than the model validations" do
      subject { matcher.between 4.seconds..20.seconds }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe "#allow_blank" do
    include WorksWithAllowBlank
  end

  describe "#with_message" do
    include WorksWithCustomMessage
  end

  describe "#on" do
    include WorksWithContext
  end

  describe "Combinations" do
    describe "#less_than + #with_message" do
      let(:model_attribute) { :less_than_with_message }

      describe "when provided with the exact duration" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.less_than 2.seconds
            matcher.with_message("File is too long.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#less_than_or_equal_to + #with_message" do
      let(:model_attribute) { :less_than_or_equal_to_with_message }

      describe "when provided with the exact duration" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.less_than_or_equal_to 2.seconds
            matcher.with_message("File is too long.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#greater_than + #with_message" do
      let(:model_attribute) { :greater_than_with_message }

      describe "when provided with the exact duration" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.greater_than 7.seconds
            matcher.with_message("File is too short.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#greater_than_or_equal_to + #with_message" do
      let(:model_attribute) { :greater_than_or_equal_to_with_message }

      describe "when provided with the exact duration" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.greater_than_or_equal_to 7.seconds
            matcher.with_message("File is too short.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#between + #with_message" do
      let(:model_attribute) { :between_with_message }

      describe "when provided with the exact duration" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.between 2.seconds..7.seconds
            matcher.with_message("File is not in accepted duration range.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end
end
