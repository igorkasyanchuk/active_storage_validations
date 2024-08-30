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
  module DoesNotMatchWithAnyValues
    extend ActiveSupport::Concern

    included do
      include LimitValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
      include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToLowerRangeBoundValue
      include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToHigherRangeBoundValue
      include LimitValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    end
  end

  module DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:lower_than_lower_range_bound_value) { 0 }

      describe 'when provided with a lower file number than the lower range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_than_lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToLowerRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:lower_range_bound_value) { 1 }

      describe 'when provided with the exact lower range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_range_bound_value) { 5 }

      describe 'when provided with the exact higher range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, higher_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_than_higher_range_bound_value) { 6 }

      describe 'when provided with a higher file number than the higher range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, higher_than_higher_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module OnlyMatchWhenExactValue
    extend ActiveSupport::Concern

    included do
      describe 'when provided with a lower file number than the file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, 1) }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'when provided with a higher file number than the file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, 5) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module OnlyMatchWhenExactValues
    extend ActiveSupport::Concern

    included do
      %i(min max).each do |number|
        describe "when provided with a lower #{number} than the #{number} specified in the model validations" do
          subject do
            matcher.min(number == :min ? 0 : 1)
            matcher.max(number == :max ? 0 : 1)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end

      describe 'when provided with the exact min and max limit of attached file specified in the model validations' do
        subject do
          matcher.min(1)
          matcher.max(5)
        end

        it { is_expected_to_match_for(klass) }
      end

      %i(min max).each do |number|
        describe "when provided with a higher #{number} than the #{number} specified in the model validations" do
          subject do
            matcher.min(number == :min ? 9 : 5)
            matcher.max(number == :max ? 9 : 5)
          end

          it { is_expected_not_to_match_for(klass) }
        end
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

  describe "#allow_blank" do
    include WorksWithAllowBlank
  end

  describe '#with_message' do
    include WorksWithCustomMessage
  end

  describe "#on" do
    include WorksWithContext
  end

  describe "#min" do
    let(:matcher_method) { :min }

    describe "when used on a minimum file attached exact validator (e.g. number of file attached: { min: 1 })" do
      let(:model_attribute) { :min_exact }

      include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
    end

    describe "when used on a minimum file attached in validator (e.g. number of file attached: { min: { in: 1..5 } })" do
      let(:model_attribute) { :min_in }
      let(:validator_lower_range_bound_value) { 1 }

      include LimitValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue

      include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToHigherRangeBoundValue
      include LimitValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    end

    describe "when used on a minimum file attached min validator (e.g. number of file attached: { min: 1 })" do
      let(:model_attribute) { :min }
      let(:validator_value) { 1 }

      include LimitValidatorMatcherTest::OnlyMatchWhenExactValue
    end

    describe "when used on a minimum file attached max validator (e.g. number of file attached: { min = max = 5 })" do
      let(:model_attribute) { :max }

      include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
    end
  end

  describe "#max" do
    let(:matcher_method) { :max }

    describe "when used on a maximum file attached exact validator (e.g. number of file attached: { max: 5 })" do
      let(:model_attribute) { :max_exact }

      include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
    end

    describe "when used on a maximum file attached in validator (e.g. number of file attached: { max: { in: 1..5 } })" do
      let(:model_attribute) { :max_in }
      let(:validator_higher_range_bound_value) { 5 }

      include LimitValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
      include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToLowerRangeBoundValue

      include LimitValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    end

    describe "when used on a maximum file attached min validator (e.g. number of file attached: { max = min = 1 })" do
      let(:model_attribute) { :min }

      include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
    end

    describe "when used on a maximum file attached max validator (e.g. number of file attached: { max: 5 })" do
      let(:model_attribute) { :max }
      let(:validator_value) { 5 }

      include LimitValidatorMatcherTest::OnlyMatchWhenExactValue
    end
  end

  describe "Combinations" do
    describe "#min + #with_message" do
      let(:model_attribute) { :min_with_message }

      describe "when used on a number of file attached minimum with message validator (e.g. { number of file attached: { min: 1 }, message: 'Invalid limits.' })" do
        describe "and when provided with the minimum number of file attached and message specified in the model validations" do
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

      describe "when used on a number of file attached maximum max with message validator (e.g. { number of file attached: { max: 5 }, message: 'Invalid limits.' })" do
        describe "and when provided with the maximum number of file attached and message specified in the model validations" do
          subject do
            matcher.public_send(:max, 5)
            matcher.with_message('Invalid limits.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    %i(min max).each do |number|
      describe "#file_number_#{number}" do
        let(:model_attribute) { :"#{number}" }

        describe "when provided with lower number of file attached than the number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"#{number}", 0)
          end

          it { is_expected_not_to_match_for(klass) }
        end

        describe "when provided with number of file attached between the number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"#{number}", 3)
          end

          it { is_expected_not_to_match_for(klass) }
        end

        describe "when provided with higher number of file attached than the number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"#{number}", 6)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end
  end
end
