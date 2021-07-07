# frozen_string_literal: true

require 'active_storage_validations/matchers/attached_validator_matcher'
require 'active_storage_validations/matchers/content_type_validator_matcher'
require 'active_storage_validations/matchers/dimension_validator_matcher'
require 'active_storage_validations/matchers/size_validator_matcher'

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
        raise 'Need either Minitest::Mock or RSpec::Mocks to run this validator matcher'
      end
    end

    def self.mock_metadata(attachment, width, height)
      if Rails.gem_version >= Gem::Version.new('6.0.0')
        # Mock the Metadata class for rails 6
        mock = OpenStruct.new(metadata: { width: width, height: height })
        stub_method(ActiveStorageValidations::Metadata, :new, mock) do
          yield
        end
      else
        # Stub the metadata analysis for rails 5
        stub_method(attachment, :analyze, true) do
          stub_method(attachment, :analyzed?, true) do
            stub_method(attachment, :metadata, { width: width, height: height }) do
              yield
            end
          end
        end
      end
    end
  end
end
