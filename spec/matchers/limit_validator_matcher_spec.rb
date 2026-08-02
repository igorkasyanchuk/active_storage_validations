# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "limit matcher only match when exact value" do
  context "when provided with a lower file count than the bound file count specified in the model validations" do
    subject(:configured_matcher) { matcher.public_send(matcher_method, 1) }

    it { is_expected_not_to_match_for(klass) }
  end

  context "when provided with the exact bound file count specified in the model validations" do
    subject(:configured_matcher) { matcher.public_send(matcher_method, validator_value) }

    it { is_expected_to_match_for(klass) }
  end

  context "when provided with a higher file count than the bound file count specified in the model validations" do
    subject(:configured_matcher) { matcher.public_send(matcher_method, 9) }

    it { is_expected_not_to_match_for(klass) }
  end
end

RSpec.describe ActiveStorageValidations::Matchers::LimitValidatorMatcher do
  let(:klass) { Limit::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"


  describe "#validate_limits_of" do
    it_behaves_like "has custom matcher"
  end

  %i[min max].each do |bound|
    describe "##{bound}" do
      let(:matcher_method) { bound }

      context "when used on a limit validator using :#{bound} (e.g. limit: { #{bound}: 3 })" do
        let(:model_attribute) { bound }
        let(:validator_value) { 3 }

        it_behaves_like "limit matcher only match when exact value"
      end
    end
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
    describe "#min + #max" do
      let(:model_attribute) { :min_max }

      context "when used on a limit validator with :min and :max (e.g. limit: { min: 1 , max: 5 })" do
        context "and when provided with the :min and :max values specified in the model validations" do
          subject(:configured_matcher) do
            matcher.public_send(:min, 1)
            matcher.public_send(:max, 5)
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#min + #with_message" do
      let(:model_attribute) { :min_with_message }

      context "when used on a :min with :message validator (e.g. limit: { min: 1 , message: 'Invalid limits.' })" do
        context "and when provided with the :min file count and :message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.public_send(:min, 1)
            matcher.with_message("Invalid limits.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#max + #with_message" do
      let(:model_attribute) { :max_with_message }

      context "when used on a :max with :message validator (e.g. limit: { max: 5 , message: 'Invalid limits.' })" do
        context "and when provided with the :max and :message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.public_send(:max, 5)
            matcher.with_message("Invalid limits.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end
end
