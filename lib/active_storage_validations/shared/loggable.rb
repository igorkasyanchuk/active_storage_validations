module ActiveStorageValidations
  module Loggable
    extend ActiveSupport::Concern

    def logger
      Rails.logger
    end
  end
end
