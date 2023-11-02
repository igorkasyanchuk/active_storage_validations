# frozen_string_literal: true

require 'test_helper'
require 'active_storage_validations/matchers'

class ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test < ActiveSupport::TestCase

  class LessThanMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than)
      matcher.less_than 2.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than)
      matcher.less_than 5.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than)
      matcher.less_than 0.5.kilobyte
      refute matcher.matches?(Size::Portfolio)
    end
  end


  class LessThanOrEqualToMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than_or_equal_to)
      matcher.less_than_or_equal_to 2.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than_or_equal_to)
      matcher.less_than_or_equal_to 5.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than_or_equal_to)
      matcher.less_than_or_equal_to 0.5.kilobyte
      refute matcher.matches?(Size::Portfolio)
    end
  end


  class GreaterThanMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than)
      matcher.greater_than 7.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than)
      matcher.greater_than 10.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than)
      matcher.greater_than 0.5.kilobyte
      refute matcher.matches?(Size::Portfolio)
    end
  end


  class GreaterThanOrEqualToMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than_or_equal_to)
      matcher.greater_than_or_equal_to 7.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than_or_equal_to)
      matcher.greater_than_or_equal_to 10.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_greater_than_or_equal_to)
      matcher.greater_than_or_equal_to 0.5.kilobyte
      refute matcher.matches?(Size::Portfolio)
    end
  end


  class BetweenMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 2.kilobytes..7.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value for highest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 2.kilobytes..10.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value for highest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 1.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value for lowest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 5.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value for lowest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 1.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided both lowest and highest possible values different than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_between)
      matcher.between 4.kilobytes..20.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end
  end

  class BetweenMatcherForManyAttachments < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 2.kilobytes..7.kilobytes
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value for highest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 2.kilobytes..10.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value for highest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 1.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a higher value than the model validation value for lowest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 5.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided a lower value than the model validation value for lowest possible size' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 1.kilobytes..7.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end

    test 'does not match when provided both lowest and highest possible values different than the model validation value' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:many_size_between)
      matcher.between 4.kilobytes..20.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end
  end

  class WithMessageMatcher < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'matches when provided with the model validation message' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_with_message)
      matcher.between 2.kilobytes..7.kilobytes
      matcher.with_message('is not in required file size range')
      assert matcher.matches?(Size::Portfolio)
    end

    test 'does not match when not provided with the model validation' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_with_message)
      matcher.between 2.kilobytes..7.kilobytes
      matcher.with_message('<wrong message>')
      refute matcher.matches?(Size::Portfolio)
    end
  end


  class UnknownAttachedAttribute < ActiveStorageValidations::Matchers::SizeValidatorMatcher::Test
    test 'does not match when provided with an unknown attached attribute' do
      matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:non_existing)
      matcher.greater_than 2.kilobytes
      refute matcher.matches?(Size::Portfolio)
    end
  end


  # Other tests
  test 'matches when provided with an instance' do
    matcher = ActiveStorageValidations::Matchers::SizeValidatorMatcher.new(:size_less_than)
    matcher.less_than 2.kilobytes
    assert matcher.matches?(Size::Portfolio.new)
  end
end
