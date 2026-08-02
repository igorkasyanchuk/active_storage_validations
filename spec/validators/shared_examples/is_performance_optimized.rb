# frozen_string_literal: true

RSpec.shared_examples "is performance optimized" do
  subject(:model) { validator_test_class::IsPerformanceOptimized.new(params) }

  let(:validator_class) { "ActiveStorageValidations::#{validator_test_class.name.delete('::')}".constantize }

  context "when the attachable blob has not been analyzed by our gem yet" do
    before { subject.is_performance_optimized.attach(attachable) }

    it "calls the corresponding media analyzer (expensive operation) once" do
      expect_any_instance_of(validator_class).to receive(:generate_metadata_for).once.and_return({})
      subject.valid?
    end
  end

  context "when an attachable blob has already been analyzed by our gem" do
    before do
      subject.is_performance_optimizeds.attach(attachable)
      subject.save!
    end

    it "only calls the corresponding media analyzer (expensive operation) on the new attachable" do
      expect_any_instance_of(validator_class).to receive(:generate_metadata_for).once.and_return({})
      subject.is_performance_optimizeds.attach(attachable)
    end
  end

  describe "persistance of the active_storage_validations metadata" do
    context "on an already saved attachable without active_storage_validations metadata (like an attachable saved before v2 of the gem)" do
      before do
        subject.is_performance_optimized.attach(attachable)
        subject.save!
        subject.is_performance_optimized.blob.update!(metadata: {})
      end

      it "persists the active_storage_validations metadata" do
        expect(subject.is_performance_optimized.blob.metadata).to eq({})

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
          expect(log_output.string).to include('Downloaded file from key:')

          log_output.truncate(0)
          log_output.rewind

          # Second validation should not log another download (in-memory validation)
          subject.valid?
          expect(log_output.string).not_to include('Downloaded file from key:')

          log_output.truncate(0)
          log_output.rewind

          # When we reload the instance, still not downloading the file (in-database validation)
          subject.reload
          subject.valid?
          expect(log_output.string).not_to include('Downloaded file from key:')
        ensure
          Rails.logger = rails_logger_was
          ActiveRecord::Base.logger = active_record_logger_was
          ActiveStorage.logger = active_storage_logger_was
        end
      end
    end

    context "on a record saved after the v2 upgrade" do
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
          expect(log_output.string).not_to include('Downloaded file from key:')

          log_output.truncate(0)
          log_output.rewind

          # When we reload the instance, still not downloading the file (in-database validation)
          subject.reload
          subject.valid?
          expect(log_output.string).not_to include('Downloaded file from key:')
        ensure
          Rails.logger = rails_logger_was
          ActiveRecord::Base.logger = active_record_logger_was
          ActiveStorage.logger = active_storage_logger_was
        end
      end
    end
  end
end
