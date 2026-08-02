# frozen_string_literal: true

RSpec.shared_examples "checks if is a valid active storage attribute" do
  context "when the passed model attribute does not exist" do
    subject(:configured_matcher) { matcher }

    let(:model_attribute) { :not_present_in_model }

    it { is_expected_not_to_match_for(klass) }
  end

  context "when the passed model attribute is not an active storage attribute" do
    subject(:configured_matcher) { matcher }

    let(:model_attribute) { :title }

    it { is_expected_not_to_match_for(klass) }
  end
end
