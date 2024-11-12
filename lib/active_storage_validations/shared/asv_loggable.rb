# frozen_string_literal: true

module ActiveStorageValidations
  module ASVLoggable
    extend ActiveSupport::Concern

    def logger
      Rails.logger
    end
  end
end
