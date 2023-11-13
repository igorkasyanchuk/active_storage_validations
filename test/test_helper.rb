# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

# Previous content of test helper now starts here

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'

# Load dummy rails application with combustion gem
require 'combustion'
Combustion.path = 'test/dummy'
Combustion.initialize! :active_record, :active_storage, :active_job do
  config.active_storage.variant_processor = ENV['IMAGE_PROCESSOR']&.to_sym
  config.active_job.queue_adapter = :inline if Rails.gem_version >= Gem::Version.new('6.0.0')
end

# Load other test helpers
require 'rails/test_help'
require 'minitest/mock'
require 'minitest/spec'
require 'minitest/focus'

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require 'rails/test_unit/reporter'
Rails::TestUnitReporter.executable = 'bin/test'

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('fixtures', __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + '/files'
  ActiveSupport::TestCase.fixtures :all
end

# Load test support files
Dir[File.join('test/support/*.rb')].map { |path| path.sub('test/', '') }.each { |f| require f }
Dir[File.join('test/matchers/support/*.rb')].map { |path| path.sub('test/', '') }.each { |f| require f }
Dir[File.join('test/validators/support/*.rb')].map { |path| path.sub('test/', '') }.each { |f| require f }

puts "Running tests with Rails v.#{Rails.version}"
