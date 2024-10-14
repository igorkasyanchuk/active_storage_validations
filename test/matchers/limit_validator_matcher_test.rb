# frozen_string_literal: true

require 'test_helper'
require 'matchers/shared_examples/checks_if_is_a_valid_active_storage_attribute'
require 'matchers/shared_examples/checks_if_is_valid'
require 'matchers/shared_examples/has_custom_matcher'
require 'matchers/shared_examples/has_valid_rspec_message_methods'
require 'matchers/shared_examples/works_with_allow_blank'
require 'matchers/shared_examples/works_with_both_instance_and_class'
require 'matchers/shared_examples/works_with_context'
require 'matchers/shared_examples/works_with_custom_message'

module LimitValidatorMatcherTest
  module OnlyMatchWhenExactValue
    extend ActiveSupport::Concern

    included do
      describe 'when provided with a lower file count than the bound file count specified in the model validations' do
        subject { matcher.public_send(matcher_method, 1) }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'when provided with the exact bound file count specified in the model validations' do
        subject { matcher.public_send(matcher_method, validator_value) }

        it { is_expected_to_match_for(klass) }
      end

      describe 'when provided with a higher file count than the bound file count specified in the model validations' do
        subject { matcher.public_send(matcher_method, 9) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end
end

describe ActiveStorageValidations::Matchers::LimitValidatorMatcher do
  include MatcherHelpers

  include ChecksIfIsAValidActiveStorageAttribute
  include ChecksIfIsValid
  include HasCustomMatcher
  include HasValidRspecMessageMethods
  include WorksWithBothInstanceAndClass

  let(:matcher) { ActiveStorageValidations::Matchers::LimitValidatorMatcher.new(model_attribute) }
  let(:klass) { Limit::Matcher }

  describe "#validate_limits_of" do
    include HasCustomMatcher
  end

  %i(min max).each do |bound|
    describe "##{bound}" do
      let(:matcher_method) { bound }

      describe "when used on a limit validator using :#{bound} (e.g. limit: { #{bound}: 3 })" do
        let(:model_attribute) { bound }
        let(:validator_value) { 3 }

        include LimitValidatorMatcherTest::OnlyMatchWhenExactValue
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

  describe "Combinations" do
    describe "#min + #max" do
      let(:model_attribute) { :min_max }

      describe "when used on a limit validator with :min and :max (e.g. limit: { min: 1 , max: 5 })" do
        describe "and when provided with the :min and :max values specified in the model validations" do
          subject do
            matcher.public_send(:min, 1)
            matcher.public_send(:max, 5)
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#min + #with_message" do
      let(:model_attribute) { :min_with_message }

      describe "when used on a :min with :message validator (e.g. limit: { min: 1 , message: 'Invalid limits.' })" do
        describe "and when provided with the :min file count and :message specified in the model validations" do
          subject do
            matcher.public_send(:min, 1)
            matcher.with_message('Invalid limits.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#max + #with_message" do
      let(:model_attribute) { :max_with_message }

      describe "when used on a :max with :message validator (e.g. limit: { max: 5 , message: 'Invalid limits.' })" do
        describe "and when provided with the :max and :message specified in the model validations" do
          subject do
            matcher.public_send(:max, 5)
            matcher.with_message('Invalid limits.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end
end
