# frozen_string_literal: true

module ActiveStorageValidations
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new(deprecation_horizon, "ActiveStorageValidations")
  end

  def self.deprecation_horizon
    @deprecation_horizon ||= "5.0"
  end
end
