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
      let(:lower_than_lower_range_bound_value) { matcher_method.match?(/_between/) ? 1..5 : 1 }

      describe 'when provided with a lower file number than the lower range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_than_lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToLowerRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:lower_range_bound_value) { matcher_method.match?(/_between/) ? 1..5 : 1 }

      describe 'when provided with the exact lower range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_range_bound_value) { matcher_method.match?(/_between/) ? 1..5 : 1 }

      describe 'when provided with the exact higher range bound file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, higher_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_than_higher_range_bound_value) { matcher_method.match?(/_between/) ? 1..5 : 1 }

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

      describe 'when provided with the exact file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, validator_value) }

        it { is_expected_to_match_for(klass) }
      end

      describe 'when provided with a higher file number than the file number specified in the model validations' do
        subject { matcher.public_send(matcher_method, 5) }

        it { is_expected_not_to_match_for(klass) }
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

  %i(file_number).each do |number|
    describe "##{number}" do
      let(:matcher_method) { number }

      describe "when used on a #{number} exact validator (e.g. number of file attached: { #{number}: 1 })" do
        let(:model_attribute) { :"#{number}_exact" }
        let(:validator_value) { 1 }

        include LimitValidatorMatcherTest::OnlyMatchWhenExactValue
      end

      describe "when used on a #{number} in validator (e.g. numberof file attached: { #{number}: { in: 1..5 } })" do
        let(:model_attribute) { :"#{number}_in" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} min validator (e.g. number of file attached: { #{number}: { min: 1 } })" do
        let(:model_attribute) { :"#{number}_min" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} max validator (e.g. number of file attached: { #{number}: { max: 5 } })" do
        let(:model_attribute) { :"#{number}_max" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{number}_between" do
      let(:matcher_method) { :"#{number}_between" }

      describe "when used on a #{number} exact validator (e.g. number of file attached: { #{number}: 1 })" do
        let(:model_attribute) { :file_number_exact }
        let(:validator_value) { 1 }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} in validator (e.g. number of file attached: { #{number}: { in: 1..5 } })" do
        let(:model_attribute) { :"#{number}_in" }

        describe "when provided with the exact lower #{number} specified in the model validations" do
          describe "and the exact higher #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 1..5) }

            it { is_expected_to_match_for(klass) }
          end

          describe "and a lower #{number} than the higher #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 1..4) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe "and a higher #{number} than the higher #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 1..6) }

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with the exact higher #{number} specified in the model validations" do
          describe "and the exact lowder #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 1..5) }

            it { is_expected_to_match_for(klass) }
          end

          describe "and a lower #{number} than the lower #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 0..5) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe "and a higher #{number} than the lower #{number} specified in the model validations" do
            subject { matcher.public_send(:"#{number}_between", 2..5) }

            it { is_expected_not_to_match_for(klass) }
          end
        end
      end

      describe "when used on a #{number} min validator (e.g. number of file attached: { #{number}: { min: 1 } })" do
        let(:model_attribute) { :"#{number}_min" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} max validator (e.g. number of file attached: { #{number}: { max: 5 } })" do
        let(:model_attribute) { :"#{number}_max" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{number}_min" do
      let(:matcher_method) { :"#{number}_min" }

      describe "when used on a #{number} exact validator (e.g. number of file attached: { #{number}: 1 })" do
        let(:model_attribute) { :"#{number}_exact" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} in validator (e.g. number of file attached: { #{number}: { in: 1..5 } })" do
        let(:model_attribute) { :"#{number}_in" }
        let(:validator_lower_range_bound_value) { 1 }

        include LimitValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue

        describe "when provided with the exact lower range bound #{number} specified in the model validations" do
          subject { matcher.public_send(matcher_method, validator_lower_range_bound_value) }

          it { is_expected_to_match_for(klass) }
        end

        include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToHigherRangeBoundValue
        include LimitValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
      end

      describe "when used on a #{number} min validator (e.g. number of file attached: { #{number}: { min: 1 } })" do
        let(:model_attribute) { :"#{number}_min" }
        let(:validator_value) { 1 }

        include LimitValidatorMatcherTest::OnlyMatchWhenExactValue
      end

      describe "when used on a #{number} max validator (e.g. number of file attached: { #{number}: { max: 5 } })" do
        let(:model_attribute) { :"#{number}_max" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{number}_max" do
      let(:matcher_method) { :"#{number}_max" }

      describe "when used on a #{number} exact validator (e.g. number of file attached: { #{number}: 150 })" do
        let(:model_attribute) { :"#{number}_exact" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} in validator (e.g. number of file attached: { #{number}: { in: 1..5 } })" do
        let(:model_attribute) { :"#{number}_in" }
        let(:validator_higher_range_bound_value) { 5 }

        include LimitValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
        include LimitValidatorMatcherTest::DoesNotMatchWhenValueEqualToLowerRangeBoundValue

        describe "when provided with the exact higher range bound #{number} specified in the model validations" do
          subject { matcher.public_send(matcher_method, validator_higher_range_bound_value) }

          it { is_expected_to_match_for(klass) }
        end

        include LimitValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
      end

      describe "when used on a #{number} min validator (e.g. number of file attached: { #{number}: { min: 1 } })" do
        let(:model_attribute) { :"#{number}_min" }

        include LimitValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{number} max validator (e.g. number of file attached: { #{number}: { max: 5 } })" do
        let(:model_attribute) { :"#{number}_max" }
        let(:validator_value) { 5 }

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
    %i(file_number).each do |number|
      describe "##{number} + #with_message" do
        let(:number_matcher_method) { number }
        let(:model_attribute) { :"#{number}_exact_with_message" }

        describe "when used on a #{number} exact with message validator (e.g. limit: { #{number}: 1, message: 'Invalid limits.' })" do
          describe "and when provided with the exact #{number} and message specified in the model validations" do
            subject do
              matcher.public_send(number_matcher_method, 1)
              matcher.with_message('Invalid limits.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{number}_between + #with_message" do
        let(:number_matcher_method) { :"#{number}_between" }
        let(:model_attribute) { :"#{number}_in_with_message" }

        describe "when used on a #{number} in with message validator (e.g. limit: { #{number}: { in: 1..5 }, message: 'Invalid limits.' })" do
          describe "and when provided with the exact #{number} range and message specified in the model validations" do
            subject do
              matcher.public_send(number_matcher_method, 1..5)
              matcher.with_message('Invalid limits.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{number}_min + #with_message" do
        let(:number_matcher_method) { :"#{number}_min" }
        let(:model_attribute) { :"#{number}_min_with_message" }

        describe "when used on a #{number} min with message validator (e.g. limit: { #{number}: { min: 1 }, message: 'Invalid limits.' })" do
          describe "and when provided with the min #{number} and message specified in the model validations" do
            subject do
              matcher.public_send(number_matcher_method, 1)
              matcher.with_message('Invalid limits.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{number}_max + #with_message" do
        let(:number_matcher_method) { :"#{number}_max" }
        let(:model_attribute) { :"#{number}_max_with_message" }

        describe "when used on a #{number} max with message validator (e.g. limit: { #{number}: { max: 5 }, message: 'Invalid limits.' })" do
          describe "and when provided with the max #{number} and message specified in the model validations" do
            subject do
              matcher.public_send(number_matcher_method, 5)
              matcher.with_message('Invalid limits.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end

    %i(min max).each do |bound|
      describe "#file_number_#{bound}" do
        let(:model_attribute) { :"#{bound}" }

        describe "when provided with lower number of file attached than the number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"file_number_#{bound}", 1)
          end

          it { is_expected_not_to_match_for(klass) }
        end

        %i(file_number).each do |number|
          describe "when provided with a lower #{number} than the #{number} specified in the model validations" do
            subject do
              matcher.public_send(:"file_number_#{bound}", number == :file_number ? 1 : 5)
            end

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with the exact number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"file_number_#{bound}", 1)
          end

          it { is_expected_to_match_for(klass) }
        end

        %i(file_number).each do |number|
          describe "when provided with a higher #{number} than the #{number} specified in the model validations" do
            subject do
              matcher.public_send(:"file_number_#{bound}", number == :file_number ? 9 : 5)
            end

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with higher number of file attached than the number of file attached specified in the model validations" do
          subject do
            matcher.public_send(:"file_number_#{bound}", 9)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end

      describe "#file_number_#{bound} + #with_message" do
        let(:model_attribute) { :"#{bound}_with_message" }

        describe "when provided with the exact number of file attached specified in the model validations" do
          describe "and when provided with the message specified in the model validations" do
            subject do
              matcher.public_send(:"file_number_#{bound}", 1)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end

    describe '#file_number' do
      describe 'when used on a number of file attached exact validator (e.g. number of file attached: { number : 1 })' do
        let(:model_attribute) { :file_number_exact }

        include LimitValidatorMatcherTest::OnlyMatchWhenExactValues
      end
    end

    describe '#file_number + #with_message' do
      let(:model_attribute) { :file_number_exact_with_message }

      describe "when used on a number of file attached exact with message validator (e.g. number of file attached: { number: 1, message: 'Invalid dimensions.' })" do
        describe 'and when provided with the exact number of file attached and message specified in the model validations' do
          subject do
            matcher.file_number(1)
            matcher.with_message('Invalid dimensions.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#file_number_between" do
      let(:model_attribute) { :file_number_in }

      describe "when provided with the number of file attached ranges specified in the model validations" do
        subject do
          matcher.file_number_between(1..5)
        end

        it { is_expected_to_match_for(klass) }

        describe "when used on a width and height min max validator (e.g. dimension: { width: { min: 800, max: 1200 }, height: { min: 600, max: 900 } })" do
          let(:model_attribute) { :width_and_height_min_max }

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#file_number_between + #with_message" do
      let(:model_attribute) { :file_number_in_with_message }

      describe "when provided with the exact number of file attached ranges specified in the model validations" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.file_number_between(1..5)
            matcher.with_message('Invalid limits.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#file_number_min + #file_number_max" do
      let(:model_attribute) { :file_number_min_max }

      describe "when provided with the width and height min max specified in the model validations" do
        subject do
          matcher.file_number_min(1)
          matcher.file_number_max(5)
        end

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
