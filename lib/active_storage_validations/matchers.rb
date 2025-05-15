# frozen_string_literal: true

require "active_storage_validations/matchers/aspect_ratio_validator_matcher"
require "active_storage_validations/matchers/attached_validator_matcher"
require "active_storage_validations/matchers/processable_file_validator_matcher"
require "active_storage_validations/matchers/limit_validator_matcher"
require "active_storage_validations/matchers/content_type_validator_matcher"
require "active_storage_validations/matchers/dimension_validator_matcher"
require "active_storage_validations/matchers/duration_validator_matcher"
require "active_storage_validations/matchers/size_validator_matcher"
require "active_storage_validations/matchers/total_size_validator_matcher"
require "active_storage_validations/matchers/pages_validator_matcher"

module ActiveStorageValidations
  module Matchers
    # Helper to stub a method with either RSpec or Minitest (whatever is available)
    def self.stub_method(object, method, result)
      if defined?(Minitest::Mock)
        object.stub(method, result) do
          yield
        end
      elsif defined?(RSpec::Mocks)
        RSpec::Mocks.allow_message(object, method) { result }
        yield
      else
        raise "Need either Minitest::Mock or RSpec::Mocks to run this validator matcher"
      end
    end

    def self.mock_metadata(attachment, metadata = {})
      asv_metadata_available_keys = { width: nil, height: nil, duration: nil, content_type: nil }
      mock = Struct.new(:metadata).new(asv_metadata_available_keys.merge(metadata)) # ensure all keys are present, and it does not raise while trying to access them

      stub_method(ActiveStorageValidations::Analyzer, :new, mock) do
        yield
      end
    end
  end
end
