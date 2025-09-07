# frozen_string_literal: true

module IsPerformanceOptimized
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::IsPerformanceOptimized.new(params) }

    let(:validator_class) { "ActiveStorageValidations::#{validator_test_class.name.delete('::')}".constantize }

    describe "when the attachable blob has not been analyzed by our gem yet" do
      before { subject.is_performance_optimized.attach(attachable) }

      it "calls the corresponding media analyzer (expensive operation) once" do
        assert_called_on_instance_of(validator_class, :generate_metadata_for, times: 1, returns: {}) do
          subject.valid?
        end
      end
    end

    describe "when an attachable blob has already been analyzed by our gem" do
      before do
        subject.is_performance_optimizeds.attach(attachable)
        subject.save!
      end

      it "only calls the corresponding media analyzer (expensive operation) on the new attachable" do
        assert_called_on_instance_of(validator_class, :generate_metadata_for, times: 1, returns: {}) do
          subject.is_performance_optimizeds.attach(attachable)
        end
      end
    end

    describe "persistance of the active_storage_validations metadata" do
      describe "on an already saved attachable without active_storage_validations metadata (like an attachable saved before v2 of the gem)" do
        before do
          subject.is_performance_optimized.attach(attachable)
          subject.save!
          subject.is_performance_optimized.blob.update!(metadata: {})
        end

        it "persists the active_storage_validations metadata" do
          assert_equal(subject.is_performance_optimized.blob.metadata, {})

          log_output = StringIO.new

          rails_logger_was = Rails.logger
          active_record_logger_was = ActiveRecord::Base.logger
          active_storage_logger_was = ActiveStorage.logger

          test_logger = Logger.new(log_output, level: Logger::DEBUG)

          Rails.logger = test_logger
          ActiveRecord::Base.logger = test_logger
          ActiveStorage.logger = test_logger

          begin
            # First validation should download the file
            subject.valid?
            assert_match(/Disk Storage.*Downloaded file from key:/, log_output.string)

            log_output.truncate(0)
            log_output.rewind

            # Second validation should not log another download (in-memory validation)
            subject.valid?
            refute_match(/Disk Storage.*Downloaded file from key:/, log_output.string)

            log_output.truncate(0)
            log_output.rewind

            # When we reload the instance, still not downloading the file (in-database validation)
            subject.reload
            subject.valid?
            refute_match(/Disk Storage.*Downloaded file from key:/, log_output.string)
          ensure
            Rails.logger = rails_logger_was
            ActiveRecord::Base.logger = active_record_logger_was
            ActiveStorage.logger = active_storage_logger_was
          end
        end
      end

      describe "on a record saved after the v2 upgrade" do
        before do
          subject.is_performance_optimized.attach(attachable)
          subject.save!
        end

        it "persists the active_storage_validations metadata" do
          log_output = StringIO.new

          rails_logger_was = Rails.logger
          active_record_logger_was = ActiveRecord::Base.logger
          active_storage_logger_was = ActiveStorage.logger

          test_logger = Logger.new(log_output, level: Logger::DEBUG)

          Rails.logger = test_logger
          ActiveRecord::Base.logger = test_logger
          ActiveStorage.logger = test_logger

          begin
            # First validation should not log another download (in-memory validation)
            subject.valid?
            refute_match(/Disk Storage.*Downloaded file from key:/, log_output.string)

            log_output.truncate(0)
            log_output.rewind

            # When we reload the instance, still not downloading the file (in-database validation)
            subject.reload
            subject.valid?
            refute_match(/Disk Storage.*Downloaded file from key:/, log_output.string)
          ensure
            Rails.logger = rails_logger_was
            ActiveRecord::Base.logger = active_record_logger_was
            ActiveStorage.logger = active_storage_logger_was
          end
        end
      end
    end
  end
end
