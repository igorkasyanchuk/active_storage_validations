# frozen_string_literal: true

RSpec.shared_examples "is performance optimized" do
  subject(:model) { validator_test_class::IsPerformanceOptimized.new(params) }

  let(:validator_class) { "ActiveStorageValidations::#{validator_test_class.name.delete('::')}".constantize }

  def with_debug_logging
    log_output = StringIO.new
    test_logger = Logger.new(log_output, level: Logger::DEBUG)

    rails_logger_was = Rails.logger
    active_record_logger_was = ActiveRecord::Base.logger
    active_storage_logger_was = ActiveStorage.logger

    Rails.logger = test_logger
    ActiveRecord::Base.logger = test_logger
    ActiveStorage.logger = test_logger

    yield log_output
  ensure
    Rails.logger = rails_logger_was
    ActiveRecord::Base.logger = active_record_logger_was
    ActiveStorage.logger = active_storage_logger_was
  end

  def clear_log(log_output)
    log_output.truncate(0)
    log_output.rewind
  end

  context "when the attachable blob has not been analyzed by our gem yet" do
    before { model.is_performance_optimized.attach(attachable) }

    it "calls the corresponding media analyzer (expensive operation) once" do
      # rubocop:disable RSpec/AnyInstance -- validator instantiated by Active Model
      expect_any_instance_of(validator_class).to receive(:generate_metadata_for).once.and_return({})
      # rubocop:enable RSpec/AnyInstance
      model.valid?
    end
  end

  context "when an attachable blob has already been analyzed by our gem" do
    before do
      model.is_performance_optimizeds.attach(attachable)
      model.save!
    end

    it "only calls the corresponding media analyzer (expensive operation) on the new attachable" do
      # rubocop:disable RSpec/AnyInstance -- validator instantiated by Active Model
      expect_any_instance_of(validator_class).to receive(:generate_metadata_for).once.and_return({})
      # rubocop:enable RSpec/AnyInstance
      model.is_performance_optimizeds.attach(attachable)
    end
  end

  describe "persistance of the active_storage_validations metadata" do
    context "with an already saved attachable without active_storage_validations metadata (like an attachable saved before v2 of the gem)" do
      before do
        model.is_performance_optimized.attach(attachable)
        model.save!
        model.is_performance_optimized.blob.update!(metadata: {})
      end

      it "persists the active_storage_validations metadata" do
        expect(model.is_performance_optimized.blob.metadata).to eq({})

        with_debug_logging do |log_output|
          model.valid?
          expect(log_output.string).to include("Downloaded file from key:")

          clear_log(log_output)
          model.valid?
          expect(log_output.string).not_to include("Downloaded file from key:")

          clear_log(log_output)
          model.reload
          model.valid?
          expect(log_output.string).not_to include("Downloaded file from key:")
        end
      end
    end

    context "with a record saved after the v2 upgrade" do
      before do
        model.is_performance_optimized.attach(attachable)
        model.save!
      end

      it "persists the active_storage_validations metadata" do
        with_debug_logging do |log_output|
          model.valid?
          expect(log_output.string).not_to include("Downloaded file from key:")

          clear_log(log_output)
          model.reload
          model.valid?
          expect(log_output.string).not_to include("Downloaded file from key:")
        end
      end
    end
  end
end
