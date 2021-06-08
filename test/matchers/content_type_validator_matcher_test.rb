# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers'

class ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher::Test < ActiveSupport::TestCase
  test 'positive match when providing class' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/png')
    matcher.rejecting('application/pdf')
    assert matcher.matches?(User)
  end

  test 'negative match when providing class' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/jpg')
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
    matcher.rejecting('application/pdf')
    assert matcher.matches?(User.new)
  end

  test 'negative match when providing instance' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:avatar)
    matcher.allowing('image/jpg')
    refute matcher.matches?(User.new)
  end

  test 'unknown attached when providing instance' do
    matcher = ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher.new(:non_existing)
    matcher.allowing('image/png')
    refute matcher.matches?(User.new)
  end
end
