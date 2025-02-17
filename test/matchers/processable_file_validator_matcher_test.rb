# frozen_string_literal: true

require "test_helper"
require "matchers/shared_examples/checks_if_is_a_valid_active_storage_attribute"
require "matchers/shared_examples/checks_if_is_valid"
require "matchers/shared_examples/has_custom_matcher"
require "matchers/shared_examples/has_valid_rspec_message_methods"
require "matchers/shared_examples/works_with_both_instance_and_class"
require "matchers/shared_examples/works_with_context"
require "matchers/shared_examples/works_with_custom_message"

describe ActiveStorageValidations::Matchers::ProcessableFileValidatorMatcher do
  include MatcherHelpers

  include ChecksIfIsAValidActiveStorageAttribute
  include ChecksIfIsValid
  include HasCustomMatcher
  include HasValidRspecMessageMethods
  include WorksWithBothInstanceAndClass

  let(:matcher) { ActiveStorageValidations::Matchers::ProcessableFileValidatorMatcher.new(model_attribute) }
  let(:klass) { ProcessableFile::Matcher }

  describe "#validate_processable_file_of" do
    include HasCustomMatcher
  end

  describe "when the passed model attribute does not have a `processable: true` constraint" do
    subject { matcher }

    let(:model_attribute) { :not_required }

    it { is_expected_not_to_match_for(klass) }
  end

  describe "#with_message" do
    include WorksWithCustomMessage
  end

  describe "#on" do
    include WorksWithContext
  end
end
