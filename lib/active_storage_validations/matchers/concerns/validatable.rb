module Validatable
  extend ActiveSupport::Concern

  private

  def validate
    @subject.validate
  end

  def validator_errors_for_attribute
    @subject.errors.details[@attribute_name].select do |error|
      error[:validator_type] == validator_class.to_sym
    end
  end

  def is_valid?
    validator_errors_for_attribute.none? do |error|
      error[:error].in?(available_errors)
    end
  end

  def available_errors
    [
      *validator_class::ERROR_TYPES,
      *error_from_custom_message
    ].compact
  end

  def validator_class
    self.class.name.gsub(/::Matchers|Matcher/, '').constantize
  end

  def error_from_custom_message
    associated_validation = @subject.class.validators_on(@attribute_name).find do |validator|
      validator.class == validator_class
    end

    associated_validation.options[:message]
  end

  def has_an_error_message_which_is_custom_message?
    validator_errors_for_attribute.one? do |error|
      error[:error] == @custom_message
    end
  end
end
