# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers::TotalSizeValidatorMatcher do
  let(:klass) { TotalSize::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"


  describe "#validate_total_size_of" do
    it_behaves_like "has custom matcher"
  end

  describe "on a has_one_attached" do
    subject(:configured_matcher) { matcher.less_than(2.kilobytes) }

    let(:has_one_class) do
      Class.new(ApplicationRecord) do
        self.table_name = "total_size_matchers"
        def self.name = "TotalSizeMatcherHasOne"
        has_one_attached :avatar
      end
    end
    let(:model_attribute) { :avatar }

    it "raises a clear error" do
      expect { configured_matcher.matches?(has_one_class) }
        .to raise_error(ArgumentError, "validate_total_size_of is only available for has_many_attached relations (:avatar is a has_one_attached)")
    end
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
    it_behaves_like "base comparison validator matcher less_than_or_equal_to rejects less_than"
  end

  describe "#greater_than" do
    let(:matcher_method) { :greater_than }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 7.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
  end

  describe "#greater_than_or_equal_to" do
    let(:matcher_method) { :greater_than_or_equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 7.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
    it_behaves_like "base comparison validator matcher greater_than_or_equal_to rejects greater_than"
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
        subject(:configured_matcher) { matcher.between 2.kilobytes..6.kilobytes }

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

    it_behaves_like "base comparison validator matcher between honors exclusive range"
  end

  describe "#equal_to" do
    let(:matcher_method) { :equal_to }
    let(:model_attribute) { matcher_method }
    let(:validator_value) { 5.kilobytes }

    it_behaves_like "base comparison validator matcher only match when exact value"
    it_behaves_like "base comparison validator matcher equal_to rejects looser comparisons"
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
            matcher.with_message("Total file size is too big.")
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
            matcher.with_message("Total file size is too big.")
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
            matcher.with_message("Total file size is too small.")
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
            matcher.with_message("Total file size is too small.")
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
            matcher.with_message("Total file size is not in accepted size range.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end

  describe "probe attachments" do
    subject(:configured_matcher) { matcher.less_than(2.kilobytes) }

    let(:model_attribute) { :less_than }

    it "does not create or upload blobs" do
      expect { configured_matcher.matches?(klass) }.not_to change(ActiveStorage::Blob, :count)
    end

    # Analyzers may copy a probe to a block-scoped tempfile of their own
    # (Rails 8.2 analyzes on attach by default); none may be left open.
    it "does not leave tempfiles open" do
      tempfiles = []
      allow(Tempfile).to receive(:new).and_wrap_original do |original, *args, **kwargs, &block|
        original.call(*args, **kwargs, &block).tap { |tempfile| tempfiles << tempfile }
      end

      configured_matcher.matches?(klass)

      expect(tempfiles).to all(be_closed)
    end
  end
end
