# frozen_string_literal: true

require 'test_helper'
require 'matchers/support/matcher_helpers'
require 'active_storage_validations/matchers'

describe ActiveStorageValidations::Matchers::SizeValidatorMatcher do
  include MatcherHelpers

  let(:matcher) { ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(model_attribute) }
  let(:klass) { Size::Portfolio }

  describe '#less_than' do
    let(:model_attribute) { :size_less_than }

    describe 'when provided with the exact size specified in the model validations' do
      subject { matcher.less_than 2.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a higher size than the size specified in the model validations' do
      subject { matcher.less_than 5.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end

    describe 'when provided with a lower size than the size specified in the model validations' do
      subject { matcher.less_than 0.5.kilobyte }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe '#less_than_or_equal_to' do
    let(:model_attribute) { :size_less_than_or_equal_to }

    describe 'when provided with the exact size specified in the model validations' do
      subject { matcher.less_than_or_equal_to 2.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a higher size than the size specified in the model validations' do
      subject { matcher.less_than_or_equal_to 5.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end

    describe 'when provided with a lower size than the size specified in the model validations' do
      subject { matcher.less_than_or_equal_to 0.5.kilobyte }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe '#greater_than' do
    let(:model_attribute) { :size_greater_than }

    describe 'when provided with the exact size specified in the model validations' do
      subject { matcher.greater_than 7.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a higher size than the size specified in the model validations' do
      subject { matcher.greater_than 10.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end

    describe 'when provided with a lower size than the size specified in the model validations' do
      subject { matcher.greater_than 0.5.kilobyte }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe '#greater_than_or_equal_to' do
    let(:model_attribute) { :size_greater_than_or_equal_to }

    describe 'when provided with the exact size specified in the model validations' do
      subject { matcher.greater_than_or_equal_to 7.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a higher size than the size specified in the model validations' do
      subject { matcher.greater_than_or_equal_to 10.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end

    describe 'when provided with a lower size than the size specified in the model validations' do
      subject { matcher.greater_than_or_equal_to 0.5.kilobyte }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe '#between' do
    let(:model_attribute) { :size_between }

    describe 'when provided with the exact sizes specified in the model validations' do
      subject { matcher.between 2.kilobytes..7.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a higher size than the size specified in the model validations' do
      describe 'for the highest possible size' do
        subject { matcher.between 2.kilobytes..10.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'for the lowest possible size' do
        subject { matcher.between 5.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe 'when provided with a lower size than the size specified in the model validations' do
      describe 'for the highest possible size' do
        subject { matcher.between 1.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'for the lowest possible size' do
        subject { matcher.between 1.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe 'when provided with both lowest and highest possible sizes different than the model validations' do
      subject { matcher.between 4.kilobytes..20.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe '#with_message' do
    before { subject.between 2.kilobytes..7.kilobytes }

    let(:model_attribute) { :size_with_message }

    describe 'when provided with the model validation message' do
      subject { matcher.with_message('is not in required file size range') }

      it { is_expected_to_match_for(klass) }
    end

    describe 'when provided with a different message than the model validation message' do
      subject { matcher.with_message('<wrong message>') }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe 'when the passed model attribute does not exist' do
    subject { matcher.less_than 2.kilobytes }

    let(:model_attribute) { :not_present_in_model }

    it { is_expected_not_to_match_for(klass) }
  end

  describe 'when the matcher is provided with an instance' do
    subject { matcher.less_than 2.kilobytes }

    let(:model_attribute) { :size_less_than }
    let(:instance) { Size::Portfolio.new }

    it { is_expected_to_match_for(instance) }
  end
end
