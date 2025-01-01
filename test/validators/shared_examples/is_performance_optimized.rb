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
  end
end
