# frozen_string_literal: true

require 'test_helper'
require 'matchers/shared_examples/checks_if_is_a_valid_active_storage_attribute'
require 'matchers/shared_examples/checks_if_is_valid'
require 'matchers/shared_examples/has_valid_rspec_message_methods'
require 'matchers/shared_examples/works_with_allow_blank'
require 'matchers/shared_examples/works_with_both_instance_and_class'
require 'matchers/shared_examples/works_with_context'
require 'matchers/shared_examples/works_with_custom_message'

module DimensionValidatorMatcherTest
  module DoesNotMatchWithAnyValues
    extend ActiveSupport::Concern

    included do
      include DimensionValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
      include DimensionValidatorMatcherTest::DoesNotMatchWhenValueEqualToLowerRangeBoundValue
      include DimensionValidatorMatcherTest::DoesNotMatchWhenValueEqualToHigherRangeBoundValue
      include DimensionValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    end
  end

  module DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:lower_than_lower_range_bound_value) { matcher_method.match?(/_between/) ? 150..200 : 150 }

      describe 'when provided with a lower width than the lower range bound width specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_than_lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToLowerRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:lower_range_bound_value) { matcher_method.match?(/_between/) ? 800..1000 : 800 }

      describe 'when provided with the exact lower range bound width specified in the model validations' do
        subject { matcher.public_send(matcher_method, lower_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenValueEqualToHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_range_bound_value) { matcher_method.match?(/_between/) ? 1200..1500 : 1200 }

      describe 'when provided with the exact higher range bound width specified in the model validations' do
        subject { matcher.public_send(matcher_method, higher_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
    extend ActiveSupport::Concern

    included do
      let(:higher_than_higher_range_bound_value) { matcher_method.match?(/_between/) ? 9999..10000 : 9999 }

      describe 'when provided with a higher width than the higher range bound width specified in the model validations' do
        subject { matcher.public_send(matcher_method, higher_than_higher_range_bound_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module OnlyMatchWhenExactValue
    extend ActiveSupport::Concern

    included do
      describe 'when provided with a lower width than the width specified in the model validations' do
        subject { matcher.public_send(matcher_method, 1) }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'when provided with the exact width specified in the model validations' do
        subject { matcher.public_send(matcher_method, validator_value) }

        it { is_expected_to_match_for(klass) }
      end

      describe 'when provided with a higher width than the width specified in the model validations' do
        subject { matcher.public_send(matcher_method, 9999) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  module OnlyMatchWhenExactValues
    extend ActiveSupport::Concern

    included do
      %i(width height).each do |dimension|
        describe "when provided with a lower #{dimension} than the #{dimension} specified in the model validations" do
          subject do
            matcher.width(dimension == :width ? 1 : 150)
            matcher.height(dimension == :height ? 1 : 150)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end

      describe 'when provided with the exact width and height specified in the model validations' do
        subject do
          matcher.width(150)
          matcher.height(150)
        end

        it { is_expected_to_match_for(klass) }
      end

      %i(width height).each do |dimension|
        describe "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
          subject do
            matcher.width(dimension == :width ? 9999 : 150)
            matcher.height(dimension == :height ? 9999 : 150)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end
  end
end

describe ActiveStorageValidations::Matchers::DimensionValidatorMatcher do
  include MatcherHelpers

  include ChecksIfIsAValidActiveStorageAttribute
  include ChecksIfIsValid
  include HasValidRspecMessageMethods
  include WorksWithBothInstanceAndClass

  let(:matcher) { ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(model_attribute) }
  let(:klass) { Dimension::Matcher }

  %i(width height).each do |dimension|
    describe "##{dimension}" do
      let(:matcher_method) { dimension }

      describe "when used on a #{dimension} exact validator (e.g. dimension: { #{dimension}: 150 })" do
        let(:model_attribute) { :"#{dimension}_exact" }
        let(:validator_value) { 150 }

        include DimensionValidatorMatcherTest::OnlyMatchWhenExactValue
      end

      describe "when used on a #{dimension} in validator (e.g. dimension: { #{dimension}: { in: 800..1200 } })" do
        let(:model_attribute) { :"#{dimension}_in" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} min validator (e.g. dimension: { #{dimension}: { min: 800 } })" do
        let(:model_attribute) { :"#{dimension}_min" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} max validator (e.g. dimension: { #{dimension}: { max: 1200 } })" do
        let(:model_attribute) { :"#{dimension}_max" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{dimension}_between" do
      let(:matcher_method) { :"#{dimension}_between" }

      describe "when used on a #{dimension} exact validator (e.g. dimension: { #{dimension}: 150 })" do
        let(:model_attribute) { :width_exact }
        let(:validator_value) { 150 }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} in validator (e.g. dimension: { #{dimension}: { in: 800..1200 } })" do
        let(:model_attribute) { :"#{dimension}_in" }

        describe "when provided with the exact lower #{dimension} specified in the model validations" do
          describe "and the exact higher #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 800..1200) }

            it { is_expected_to_match_for(klass) }
          end

          describe "and a lower #{dimension} than the higher #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 800..1000) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe "and a higher #{dimension} than the higher #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 800..9999) }

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with the exact higher #{dimension} specified in the model validations" do
          describe "and the exact lowder #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 800..1200) }

            it { is_expected_to_match_for(klass) }
          end

          describe "and a lower #{dimension} than the lower #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 1..1200) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe "and a higher #{dimension} than the lower #{dimension} specified in the model validations" do
            subject { matcher.public_send(:"#{dimension}_between", 1000..1200) }

            it { is_expected_not_to_match_for(klass) }
          end
        end
      end

      describe "when used on a #{dimension} min validator (e.g. dimension: { #{dimension}: { min: 1200 } })" do
        let(:model_attribute) { :"#{dimension}_min" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} max validator (e.g. dimension: { #{dimension}: { max: 1200 } })" do
        let(:model_attribute) { :"#{dimension}_max" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{dimension}_min" do
      let(:matcher_method) { :"#{dimension}_min" }

      describe "when used on a #{dimension} exact validator (e.g. dimension: { #{dimension}: 150 })" do
        let(:model_attribute) { :"#{dimension}_exact" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} in validator (e.g. dimension: { #{dimension}: { in: 800..1200 } })" do
        let(:model_attribute) { :"#{dimension}_in" }
        let(:validator_lower_range_bound_value) { 800 }

        include DimensionValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue

        describe "when provided with the exact lower range bound #{dimension} specified in the model validations" do
          subject { matcher.public_send(matcher_method, validator_lower_range_bound_value) }

          it { is_expected_to_match_for(klass) }
        end

        include DimensionValidatorMatcherTest::DoesNotMatchWhenValueEqualToHigherRangeBoundValue
        include DimensionValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
      end

      describe "when used on a #{dimension} min validator (e.g. dimension: { #{dimension}: { min: 800 } })" do
        let(:model_attribute) { :"#{dimension}_min" }
        let(:validator_value) { 800 }

        include DimensionValidatorMatcherTest::OnlyMatchWhenExactValue
      end

      describe "when used on a #{dimension} max validator (e.g. dimension: { #{dimension}: { max: 1200 } })" do
        let(:model_attribute) { :"#{dimension}_max" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end
    end

    describe "##{dimension}_max" do
      let(:matcher_method) { :"#{dimension}_max" }

      describe "when used on a #{dimension} exact validator (e.g. dimension: { #{dimension}: 150 })" do
        let(:model_attribute) { :"#{dimension}_exact" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} in validator (e.g. dimension: { #{dimension}: { in: 800..1200 } })" do
        let(:model_attribute) { :"#{dimension}_in" }
        let(:validator_higher_range_bound_value) { 1200 }

        include DimensionValidatorMatcherTest::DoesNotMatchWhenLowerValueThanLowerRangeBoundValue
        include DimensionValidatorMatcherTest::DoesNotMatchWhenValueEqualToLowerRangeBoundValue

        describe "when provided with the exact higher range bound #{dimension} specified in the model validations" do
          subject { matcher.public_send(matcher_method, validator_higher_range_bound_value) }

          it { is_expected_to_match_for(klass) }
        end

        include DimensionValidatorMatcherTest::DoesNotMatchWhenHigherValueThanHigherRangeBoundValue
      end

      describe "when used on a #{dimension} min validator (e.g. dimension: { #{dimension}: { min: 800 } })" do
        let(:model_attribute) { :"#{dimension}_min" }

        include DimensionValidatorMatcherTest::DoesNotMatchWithAnyValues
      end

      describe "when used on a #{dimension} max validator (e.g. dimension: { #{dimension}: { max: 1200 } })" do
        let(:model_attribute) { :"#{dimension}_max" }
        let(:validator_value) { 1200 }

        include DimensionValidatorMatcherTest::OnlyMatchWhenExactValue
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
    %i(width height).each do |dimension|
      describe "##{dimension} + #with_message" do
        let(:dimension_matcher_method) { dimension }
        let(:model_attribute) { :"#{dimension}_exact_with_message" }

        describe "when used on a #{dimension} exact with message validator (e.g. dimension: { #{dimension}: 150, message: 'Invalid dimensions.' })" do
          describe "and when provided with the exact #{dimension} and message specified in the model validations" do
            subject do
              matcher.public_send(dimension_matcher_method, 150)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{dimension}_between + #with_message" do
        let(:dimension_matcher_method) { :"#{dimension}_between" }
        let(:model_attribute) { :"#{dimension}_in_with_message" }

        describe "when used on a #{dimension} in with message validator (e.g. dimension: { #{dimension}: { in: 800..1200 }, message: 'Invalid dimensions.' })" do
          describe "and when provided with the exact #{dimension} range and message specified in the model validations" do
            subject do
              matcher.public_send(dimension_matcher_method, 800..1200)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{dimension}_min + #with_message" do
        let(:dimension_matcher_method) { :"#{dimension}_min" }
        let(:model_attribute) { :"#{dimension}_min_with_message" }

        describe "when used on a #{dimension} min with message validator (e.g. dimension: { #{dimension}: { min: 800 }, message: 'Invalid dimensions.' })" do
          describe "and when provided with the min #{dimension} and message specified in the model validations" do
            subject do
              matcher.public_send(dimension_matcher_method, 800)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end

      describe "##{dimension}_max + #with_message" do
        let(:dimension_matcher_method) { :"#{dimension}_max" }
        let(:model_attribute) { :"#{dimension}_max_with_message" }

        describe "when used on a #{dimension} max with message validator (e.g. dimension: { #{dimension}: { max: 1200 }, message: 'Invalid dimensions.' })" do
          describe "and when provided with the max #{dimension} and message specified in the model validations" do
            subject do
              matcher.public_send(dimension_matcher_method, 1200)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end

    %i(min max).each do |bound|
      describe "#width_#{bound} + #height_#{bound}" do
        let(:model_attribute) { :"#{bound}" }

        describe "when provided with both lower width and height than the width and height specified in the model validations" do
          subject do
            matcher.public_send(:"width_#{bound}", 1)
            matcher.public_send(:"height_#{bound}", 1)
          end

          it { is_expected_not_to_match_for(klass) }
        end

        %i(width height).each do |dimension|
          describe "when provided with a lower #{dimension} than the #{dimension} specified in the model validations" do
            subject do
              matcher.public_send(:"width_#{bound}", dimension == :width ? 1 : 800)
              matcher.public_send(:"height_#{bound}", dimension == :height ? 1 : 600)
            end

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with the exact width and height specified in the model validations" do
          subject do
            matcher.public_send(:"width_#{bound}", 800)
            matcher.public_send(:"height_#{bound}", 600)
          end

          it { is_expected_to_match_for(klass) }
        end

        %i(width height).each do |dimension|
          describe "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
            subject do
              matcher.public_send(:"width_#{bound}", dimension == :width ? 9999 : 800)
              matcher.public_send(:"height_#{bound}", dimension == :height ? 9999 : 600)
            end

            it { is_expected_not_to_match_for(klass) }
          end
        end

        describe "when provided with both higher width and height than the width and height specified in the model validations" do
          subject do
            matcher.public_send(:"width_#{bound}", 9999)
            matcher.public_send(:"height_#{bound}", 9999)
          end

          it { is_expected_not_to_match_for(klass) }
        end
      end

      describe "#width_#{bound} + #height_#{bound} + #with_message" do
        let(:model_attribute) { :"#{bound}_with_message" }

        describe "when provided with the exact width and height specified in the model validations" do
          describe "and when provided with the message specified in the model validations" do
            subject do
              matcher.public_send(:"width_#{bound}", 800)
              matcher.public_send(:"height_#{bound}", 600)
              matcher.with_message('Invalid dimensions.')
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end

    describe '#width + #height' do
      describe 'when used on a width exact and height exact validator (e.g. dimension: { width: 150, height: 150 })' do
        let(:model_attribute) { :width_and_height_exact }

        include DimensionValidatorMatcherTest::OnlyMatchWhenExactValues
      end
    end

    describe '#width + #height + #with_message' do
      let(:model_attribute) { :width_and_height_exact_with_message }

      describe "when used on a width exact and height exact with message validator (e.g. dimension: { width: 150, height: 150, message: 'Invalid dimensions.' })" do
        describe 'and when provided with the exact width, height and message specified in the model validations' do
          subject do
            matcher.width(150)
            matcher.height(150)
            matcher.with_message('Invalid dimensions.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#width_between + #height_between" do
      let(:model_attribute) { :width_and_height_in }

      describe "when provided with the width and height ranges specified in the model validations" do
        subject do
          matcher.width_between(800..1200)
          matcher.height_between(600..900)
        end

        it { is_expected_to_match_for(klass) }

        describe "when used on a width and height min max validator (e.g. dimension: { width: { min: 800, max: 1200 }, height: { min: 600, max: 900 } })" do
          let(:model_attribute) { :width_and_height_min_max }

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#width_between + #height_between + #with_message" do
      let(:model_attribute) { :width_and_height_in_with_message }

      describe "when provided with the exact width and height ranges specified in the model validations" do
        describe "and when provided with the message specified in the model validations" do
          subject do
            matcher.width_between(800..1200)
            matcher.height_between(600..900)
            matcher.with_message('Invalid dimensions.')
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#width_min + #width_max + #height_min + #height_max" do
      let(:model_attribute) { :width_and_height_min_max }

      describe "when provided with the width and height min max specified in the model validations" do
        subject do
          matcher.width_min(800)
          matcher.width_max(1200)
          matcher.height_min(600)
          matcher.height_max(900)
        end

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
