# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  command_name "RSpec"
  # `skip` is SimpleCov >= 1.0; older gemfiles (Rails 7.0/7.1) still resolve 0.22
  %w[/spec/ /test/ /vendor/].each do |path|
    if respond_to?(:skip)
      skip path
    else
      add_filter path
    end
  end
end

require "webmock/rspec"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
