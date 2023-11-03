# frozen_string_literal: true

# Run tests using:
# BUNDLE_GEMFILE=gemfiles/rails_5_2.gemfile bundle exec rake test
# BUNDLE_GEMFILE=gemfiles/rails_6_0.gemfile bundle exec rake test

require 'test_helper'

class ActiveStorageValidations::SizeValidator::Test < ActiveSupport::TestCase

  class LessThanValidator < ActiveStorageValidations::SizeValidator::Test
    # validates :size_less_than, size: { less_than: 2.kilobytes }

    test 'validates attached file when size is stricly less than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than.attach(file_1ko)
      pt.proc_size_less_than.attach(file_1ko)

      assert pt.valid?
    end

    test 'does not validate attached file when size is equal to the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than.attach(file_2ko)
      pt.proc_size_less_than.attach(file_2ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size less than file size must be less than 2 KB (current size is 2 KB)',
        'Proc size less than file size must be less than 2 KB (current size is 2 KB)'
      ]
    end

    test 'does not validate attached file when size is stricly higher than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than.attach(file_10ko)
      pt.proc_size_less_than.attach(file_10ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size less than file size must be less than 2 KB (current size is 10 KB)',
        'Proc size less than file size must be less than 2 KB (current size is 10 KB)'
      ]
    end
  end


  class LessThanOrEqualToValidator < ActiveStorageValidations::SizeValidator::Test
    # validates :size_less_than_or_equal_to, size: { less_than_or_equal_to: 2.kilobytes }

    test 'validates attached file when size is stricly less than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than_or_equal_to.attach(file_1ko)
      pt.proc_size_less_than_or_equal_to.attach(file_1ko)

      assert pt.valid?
    end

    test 'validates attached file when size is equal to the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than_or_equal_to.attach(file_2ko)
      pt.proc_size_less_than_or_equal_to.attach(file_2ko)

      assert pt.valid?
    end

    test 'does not validate attached file when size is stricly higher than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_less_than_or_equal_to.attach(file_10ko)
      pt.proc_size_less_than_or_equal_to.attach(file_10ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size less than or equal to file size must be less than or equal to 2 KB (current size is 10 KB)',
        'Proc size less than or equal to file size must be less than or equal to 2 KB (current size is 10 KB)'
      ]
    end
  end


  class GreaterThanValidator < ActiveStorageValidations::SizeValidator::Test
    # validates :size_greater_than, size: { greater_than: 7.kilobytes }

    test 'validates attached file when size is stricly greater than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than.attach(file_10ko)
      pt.proc_size_greater_than.attach(file_10ko)

      assert pt.valid?
    end

    test 'does not validate attached file when size is equal to the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than.attach(file_7ko)
      pt.proc_size_greater_than.attach(file_7ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size greater than file size must be greater than 7 KB (current size is 7 KB)',
        'Proc size greater than file size must be greater than 7 KB (current size is 7 KB)'
      ]
    end

    test 'does not validate attached file when size is stricly less than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than.attach(file_2ko)
      pt.proc_size_greater_than.attach(file_2ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size greater than file size must be greater than 7 KB (current size is 2 KB)',
        'Proc size greater than file size must be greater than 7 KB (current size is 2 KB)'
      ]
    end
  end


  class GreaterThanOrEqualToValidator < ActiveStorageValidations::SizeValidator::Test
    # validates :size_greater_than_or_equal_to, size: { greater_than_or_equal_to: 7.kilobytes }

    test 'validates attached file when size is stricly greater than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than_or_equal_to.attach(file_10ko)
      pt.proc_size_greater_than_or_equal_to.attach(file_10ko)

      assert pt.valid?
    end

    test 'validates attached file when size is equal to the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than_or_equal_to.attach(file_7ko)
      pt.proc_size_greater_than_or_equal_to.attach(file_7ko)

      assert pt.valid?
    end

    test 'does not validate attached file when size is stricly less than the model validation value' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_greater_than_or_equal_to.attach(file_2ko)
      pt.proc_size_greater_than_or_equal_to.attach(file_2ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size greater than or equal to file size must be greater than or equal to 7 KB (current size is 2 KB)',
        'Proc size greater than or equal to file size must be greater than or equal to 7 KB (current size is 2 KB)'
      ]
    end
  end


  class BetweenValidator < ActiveStorageValidations::SizeValidator::Test
    # validates :size_between, size: { between: 2..7.kilobytes }

    test 'validates attached file when size is in the model validation value range' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_between.attach(file_5ko)
      pt.proc_size_between.attach(file_5ko)

      assert pt.valid?
    end

    test 'validates attached file when size is equal to the lowest possible value of the model validation value range' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_between.attach(file_2ko)
      pt.proc_size_between.attach(file_2ko)

      assert pt.valid?
    end

    test 'validates attached file when size is equal to the highest possible value of the model validation value range' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_between.attach(file_7ko)
      pt.proc_size_between.attach(file_7ko)

      assert pt.valid?
    end

    test 'does not validate attached file when size is stricly less than the model validation value range' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_between.attach(file_1ko)
      pt.proc_size_between.attach(file_1ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size between file size must be between 2 KB and 7 KB (current size is 1 KB)',
        'Proc size between file size must be between 2 KB and 7 KB (current size is 1 KB)'
      ]
    end

    test 'does not validate attached file when size is stricly higher than the model validation value range' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_between.attach(file_10ko)
      pt.proc_size_between.attach(file_10ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size between file size must be between 2 KB and 7 KB (current size is 10 KB)',
        'Proc size between file size must be between 2 KB and 7 KB (current size is 10 KB)'
      ]
    end
  end


  class WithMessage < ActiveStorageValidations::SizeValidator::Test
    # validates :size_with_message, size: { between: 2.kilobytes..7.kilobytes, message: 'is not in required file size range' }

    test 'generates the custom error message when the attached file is not valid' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_with_message.attach(file_10ko)
      pt.proc_size_with_message.attach(file_10ko)

      refute pt.valid?
      assert_equal pt.errors.full_messages, [
        'Size with message is not in required file size range',
        'Proc size with message file size must be between 2 KB and 7 KB (current size is 10 KB)'
      ]
    end
  end

  class ValidatorValidity < ActiveStorageValidations::SizeValidator::Test
    def error_message
      'You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), or :between to the validator'
    end

    test 'ensures that at least 1 size validator has been used' do
      assert_raises(ArgumentError, error_message) { Size::ZeroValidator.new(title: 'Raises error') }
    end

    test 'ensures that at least 1 size validator has been used when using a Proc' do
      assert_raises(ArgumentError, error_message) { Size::ZeroValidatorProc.new(title: 'Raises error') }
    end

    test 'ensures that no more than 1 size validator has been used' do
      assert_raises(ArgumentError, error_message) { Size::SeveralValidator.new(title: 'Raises error') }
    end

    test 'ensures that no more than 1 size validator has been used when using a Proc' do
      assert_raises(ArgumentError, error_message) { Size::SeveralValidatorProc.new(title: 'Raises error') }
    end
  end

  class WithContext < ActiveStorageValidations::SizeValidator::Test
    # validates :size_with_context, size: { less_than: 2.kilobytes }, on: :custom_context

    test 'generates correct error message' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_with_context.attach(file_10ko)

      refute pt.invalid?
      pt.valid?(:custom_context)

      assert_equal(
        ['Size with context file size must be less than 2 KB (current size is 10 KB)'],
        pt.errors.full_messages
      )
    end
  end

  class WithIf < ActiveStorageValidations::SizeValidator::Test
    #   validates :size_with_if, size: { less_than: 2.kilobytes }, if: -> {  title == 'very_nice_title' }

    test 'generates correct error message' do
      pt = Size::Portfolio.new(title: 'Matisse')
      pt.size_with_if.attach(file_10ko)

      refute pt.invalid?

      pt.title = 'very_nice_title'
      refute pt.valid?

      assert_equal(
        ['Size with if file size must be less than 2 KB (current size is 10 KB)'],
        pt.errors.full_messages
      )
    end
  end
end

def file_1ko
  {
    io: File.open(Rails.root.join('public', 'file_1ko')),
    filename: 'file_1ko',
    content_type: 'image/png'
  }
end

def file_2ko
  {
    io: File.open(Rails.root.join('public', 'file_2ko')),
    filename: 'file_2ko',
    content_type: 'text/html'
  }
end

def file_5ko
  {
    io: File.open(Rails.root.join('public', 'file_5ko')),
    filename: 'file_5ko',
    content_type: 'text/html'
  }
end

def file_7ko
  {
    io: File.open(Rails.root.join('public', 'file_7ko')),
    filename: 'file_7ko',
    content_type: 'text/html'
  }
end

def file_10ko
  {
    io: File.open(Rails.root.join('public', 'file_10ko')),
    filename: 'file_10ko',
    content_type: 'text/html'
  }
end
