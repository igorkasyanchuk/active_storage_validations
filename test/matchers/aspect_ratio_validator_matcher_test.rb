# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers'

class ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher::Test < ActiveSupport::TestCase
  test 'positive match portrait' do
    matcher = ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher.new(:portrait_image, :portrait)
    assert matcher.matches?(RatioModel)
  end

  test 'positive match landscape' do
    matcher = ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher.new(:landscape_image, :landscape)
    assert matcher.matches?(RatioModel)
  end

  test 'positive match squared' do
    matcher = ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher.new(:squared_image, :squared)
    assert matcher.matches?(RatioModel)
  end

  test 'positive match widescreen' do
    matcher = ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher.new(:widescreen_image, :is_16_9)
    assert matcher.matches?(RatioModel)
  end
end
