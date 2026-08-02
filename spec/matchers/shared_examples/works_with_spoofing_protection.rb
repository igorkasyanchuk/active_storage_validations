# frozen_string_literal: true

RSpec.shared_examples "works with spoofing protection" do
  let(:model_attribute) { :with_spoofing_protection }

  context "when provided with the other validator requirements" do
    before { matcher.allowing("image/png") }

    context "and when provided with the model validation spoofing_protection" do
      subject(:configured_matcher) { matcher.spoofing_protection }

      it { is_expected_to_match_for(klass) }
    end

    context "and when provided with spoofing_protection: :file" do
      subject(:configured_matcher) { matcher.spoofing_protection(:file) }

      it { is_expected_to_match_for(klass) }
    end

    context "and when provided with a different spoofing_protection than the model validation" do
      subject(:configured_matcher) { matcher.spoofing_protection(:magika) }

      it { is_expected_not_to_match_for(klass) }
    end

    context "and when not provided with the #spoofing_protection matcher method" do
      subject(:configured_matcher) { matcher }

      it { is_expected_to_match_for(klass) }
    end
  end

  # Option-only checks: do not call #allowing here, so Magika CLI is not required locally.
  context "when the model uses spoofing_protection: :magika" do
    let(:model_attribute) { :with_spoofing_protection_magika }

    context "and when provided with spoofing_protection: :magika" do
      subject(:configured_matcher) { matcher.spoofing_protection(:magika) }

      it { is_expected_to_match_for(klass) }
    end

    context "and when provided with spoofing_protection: true" do
      subject(:configured_matcher) { matcher.spoofing_protection }

      it { is_expected_not_to_match_for(klass) }
    end
  end
end
