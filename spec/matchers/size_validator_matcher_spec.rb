# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers::SizeValidatorMatcher do
  let(:klass) { Size::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"


  describe "#validate_size_of" do
    it_behaves_like "has custom matcher"
  end

  describe "#less_than" do
    let(:matcher_method) { :less_than }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 2.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
  end

  describe "#less_than_or_equal_to" do
    let(:matcher_method) { :less_than_or_equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 2.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
  end

  describe "#greater_than" do
    let(:matcher_method) { :greater_than }
    let(:validator_value) { 7.kilobytes }

    context "with has_one_attached" do
      let(:model_attribute) { matcher_method }

      it_behaves_like "base comparison validator matcher only match when exact value"
    end

    context "with has_many_attached" do
      let(:model_attribute) { :many_greater_than }

      it_behaves_like "base comparison validator matcher only match when exact value"
    end
  end

  describe "#greater_than_or_equal_to" do
    let(:matcher_method) { :greater_than_or_equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 7.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
  end

  describe "#between" do
    let(:model_attribute) { :between }

    context "when provided with the exact sizes specified in the model validations" do
      subject(:configured_matcher) { matcher.between 2.kilobytes..7.kilobytes }

      it { is_expected_to_match_for(klass) }
    end

    context "when provided with a higher size than the size specified in the model validations" do
      describe "for the highest possible size" do
        subject(:configured_matcher) { matcher.between 2.kilobytes..10.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end

      describe "for the lowest possible size" do
        subject(:configured_matcher) { matcher.between 5.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    context "when provided with a lower size than the size specified in the model validations" do
      describe "for the highest possible size" do
        subject(:configured_matcher) { matcher.between 1.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end

      describe "for the lowest possible size" do
        subject(:configured_matcher) { matcher.between 1.kilobytes..7.kilobytes }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    context "when provided with both lowest and highest possible sizes different than the model validations" do
      subject(:configured_matcher) { matcher.between 4.kilobytes..20.kilobytes }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe "#equal_to" do
    let(:matcher_method) { :equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 5.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
  end

  describe "#allow_blank" do
    it_behaves_like "works with allow_blank"
  end

  describe "#with_message" do
    it_behaves_like "works with custom message"
  end

  describe "#on" do
    it_behaves_like "works with context"
  end

  describe "#except_on" do
    it_behaves_like "works with except_on"
  end

  describe "Combinations" do
    describe "#less_than + #with_message" do
      let(:model_attribute) { :less_than_with_message }

      context "when provided with the exact size" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.less_than 2.kilobytes
            matcher.with_message("File is too big.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#less_than_or_equal_to + #with_message" do
      let(:model_attribute) { :less_than_or_equal_to_with_message }

      context "when provided with the exact size" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.less_than_or_equal_to 2.kilobytes
            matcher.with_message("File is too big.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#greater_than + #with_message" do
      let(:model_attribute) { :greater_than_with_message }

      context "when provided with the exact size" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.greater_than 7.kilobytes
            matcher.with_message("File is too small.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#greater_than_or_equal_to + #with_message" do
      let(:model_attribute) { :greater_than_or_equal_to_with_message }

      context "when provided with the exact size" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.greater_than_or_equal_to 7.kilobytes
            matcher.with_message("File is too small.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#between + #with_message" do
      let(:model_attribute) { :between_with_message }

      context "when provided with the exact size" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.between 2.kilobyte..7.kilobytes
            matcher.with_message("File is not in accepted size range.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end
end
