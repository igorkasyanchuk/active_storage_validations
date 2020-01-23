# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers/attached_validator_matcher'

class ActiveStorageValidations::Matchers::AttachedValidatorMatcher::Test < ActiveSupport::TestCase
  test 'positive match when providing class' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:avatar)
    assert matcher.matches?(User)
  end

  test 'negative match when providing class' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:image_regex)
    refute matcher.matches?(User)
  end

  test 'unkown attached when providing class' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:non_existing)
    refute matcher.matches?(User)
  end

  test 'positive match when providing instance' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:avatar)
    assert matcher.matches?(User.new)
  end

  test 'negative match when providing instance' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:image_regex)
    refute matcher.matches?(User.new)
  end

  test 'unkown attached when providing instance' do
    matcher = ActiveStorageValidations::Matchers::AttachedValidatorMatcher.new(:non_existing)
    refute matcher.matches?(User.new)
  end
end
