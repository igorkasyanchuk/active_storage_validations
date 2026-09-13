# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers::WithAudioValidatorMatcher do
  let(:klass) { WithAudio::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"

  describe "#validate_with_audio_of" do
    it_behaves_like "has custom matcher"
  end

  context "when the passed model attribute does not have a `with_audio` constraint" do
    subject(:configured_matcher) { matcher }

    let(:model_attribute) { :not_validated }

    it { is_expected_not_to_match_for(klass) }
  end

  describe "#without_audio" do
    subject(:configured_matcher) { matcher.without_audio }

    let(:model_attribute) { :silent_video }

    it { is_expected_to_match_for(klass) }
  end

  describe "#allow_blank" do
    it_behaves_like "works with allow_blank"
  end

  describe "#with_message" do
    it_behaves_like "works with custom message"
  end

  describe "Combinations" do
    describe "#without_audio + #with_message" do
      let(:model_attribute) { :without_audio_with_message }

      context "when provided with the message specified in the model validations" do
        subject(:configured_matcher) { matcher.without_audio.with_message("Custom message") }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with a different message than the model validation message" do
        subject(:configured_matcher) { matcher.without_audio.with_message("<wrong message>") }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  describe "#on" do
    it_behaves_like "works with context"
  end

  describe "#except_on" do
    it_behaves_like "works with except_on"
  end

  describe "#timeout" do
    it_behaves_like "works with timeout"
  end
end
