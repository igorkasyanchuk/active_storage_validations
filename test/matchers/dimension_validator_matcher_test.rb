# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers/dimension_validator_matcher'

class ActiveStorageValidations::Matchers::DimensionValidatorMatcher::Test < ActiveSupport::TestCase
  test 'width positive match on lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_min 800
    assert matcher.matches?(Project)
  end

  test 'width less than lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_min 700
    refute matcher.matches?(Project)
  end

  test 'width higher than lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_min 900
    refute matcher.matches?(Project)
  end

  test 'width positive match on higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_max 1200
    assert matcher.matches?(Project)
  end

  test 'width less than higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_max 1100
    refute matcher.matches?(Project)
  end

  test 'width higher than higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.width_max 1300
    refute matcher.matches?(Project)
  end

  test 'height positive match on lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_min 600
    assert matcher.matches?(Project)
  end

  test 'height less than lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_min 500
    refute matcher.matches?(Project)
  end

  test 'height higher than lower' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_min 700
    refute matcher.matches?(Project)
  end

  test 'height positive match on higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_max 900
    assert matcher.matches?(Project)
  end

  test 'height less than higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_max 800
    refute matcher.matches?(Project)
  end

  test 'height higher than higher' do
    matcher = ActiveStorageValidations::Matchers::DimensionValidatorMatcher.new(:dimension_range)
    matcher.height_max 1000
    refute matcher.matches?(Project)
  end
end
