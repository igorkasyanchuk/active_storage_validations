# frozen_string_literal: true

require 'test_helper'
require 'matchers/shared_examples/works_with_context'
require 'matchers/shared_examples/works_with_custom_message'

describe ActiveStorageValidations::Matchers::AttachedValidatorMatcher do
  include MatcherHelpers

  let(:matcher) { ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(model_attribute) }
  let(:klass) { Attached::Matcher }

  describe '#with_message' do
    include WorksWithCustomMessage
  end

  describe "#on" do
    include WorksWithContext
  end

  describe 'when the passed model attribute' do
    describe 'does not exist' do
      subject { matcher }

      let(:model_attribute) { :not_present_in_model }

      it { is_expected_not_to_match_for(klass) }
    end

    describe 'does not have an `attached: true` constraint' do
      subject { matcher }

      let(:model_attribute) { :not_required }

      it { is_expected_not_to_match_for(klass) }
    end
  end

  describe 'when the matcher is provided with an instance' do
    subject { matcher }

    let(:model_attribute) { :required }
    let(:instance) { klass.new }

    it { is_expected_to_match_for(instance) }
  end
end
