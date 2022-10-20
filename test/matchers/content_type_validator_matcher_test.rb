# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers'

class ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher::Test < ActiveSupport::TestCase
  test 'positive and negative' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/png')
    assert_raise(ArgumentError) { matcher.rejecting('image/jpg') }
  end

  test 'negative and positive' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.rejecting('image/png')
    assert_raise(ArgumentError) { matcher.allowing('image/jpg') }
  end

  test 'positive match when providing class' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/png')
    assert matcher.matches?(User)
  end

  test 'negative match when providing class' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/jpeg')
    refute matcher.matches?(User)
  end

  test 'unknown attached when providing class' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:non_existing)
    matcher.allowing('image/png')
    refute matcher.matches?(User)
  end

  test 'positive match when providing instance' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/png')
    assert matcher.matches?(User.new)
  end

  test 'negative match when providing instance' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/jpeg')
    refute matcher.matches?(User.new)
  end

  test 'unknown attached when providing instance' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:non_existing)
    matcher.allowing('image/png')
    refute matcher.matches?(User.new)
  end

  test 'positive match for rejecting' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.rejecting('image/jpeg')
    assert matcher.matches?(User)
  end

  test 'negative match for rejecting' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.rejecting('image/png')
    refute matcher.matches?(User)
  end
end
