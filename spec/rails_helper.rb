# frozen_string_literal: true

return if defined?(ASV_RAILS_HELPER_LOADED)

ASV_RAILS_HELPER_LOADED = true

require "spec_helper"

ENV["RAILS_ENV"] = "test"

require "combustion"
Combustion.path = "test/dummy"
Combustion.initialize! :active_record, :active_storage, :active_job do
  config.active_storage.variant_processor = ENV["IMAGE_PROCESSOR"]&.to_sym

  # Uncomment this to test S3 services
  # require "aws-sdk-s3"
  # config.active_storage.service = :digitalocean

  config.active_job.queue_adapter = :inline

  # Active Storage enqueues PreviewImageJob on attach when system previewers
  # (poppler / ffmpeg) are present. That path requires the image_processing gem,
  # which this project does not use (analyzers call mini_magick / ruby-vips /
  # pdfinfo directly). Disable previewers so PDF/video saves do not fail in CI.
  config.active_storage.previewers = []
end

require "rspec/rails"

# Support files (file helpers, locale, mime types)
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }

# Area-specific helpers
Dir[File.expand_path("{validators,matchers,analyzers}/support/**/*.rb", __dir__)].sort.each { |f| require f }

# Shared examples
Dir[File.expand_path("{validators,matchers,analyzers}/shared_examples/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [ File.expand_path("../test/fixtures", __dir__) ] if config.respond_to?(:fixture_paths=)
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # CI matrix sets IMAGE_PROCESSOR; omit mismatched :image_processor examples
  # entirely (not pending). Unset locally so a targeted file path still runs.
  if ENV.key?("IMAGE_PROCESSOR")
    processor = ENV["IMAGE_PROCESSOR"].to_sym
    config.filter_run_excluding image_processor: ->(value) { value && value != processor }
  end

  config.include ValidatorHelpers, file_path: %r{spec/validators}
  config.include MatcherHelpers, file_path: %r{spec/matchers}
  config.include AnalyzerHelpers, file_path: %r{spec/analyzers}

  # Helpers return `{ io: File.open(...) }` and many examples open fixture
  # Files directly. MRI only releases those FDs when GC runs, so a full
  # local run can hit Errno::EMFILE when SimpleCov locks the resultset.
  config.after { close_leaked_fixture_ios }

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join("tmp/storage"))
  end
end

def close_leaked_fixture_ios
  public_root = Rails.root.join("public").to_s

  ObjectSpace.each_object(File) do |file|
    next if file.closed?

    path = file.path
    file.close if path&.start_with?(public_root)
  rescue IOError, Errno::EBADF
    # already closed between the check and close
  end
end

puts "Running specs with Rails v.#{Rails.version}"
