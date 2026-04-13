# frozen_string_literal: true

module ActiveStorageValidations
  module ASVLoggable
    extend ActiveSupport::Concern

    def logger
      defined?(Rails) ? Rails.logger : Logger.new($stdout)
    end
  end
end
