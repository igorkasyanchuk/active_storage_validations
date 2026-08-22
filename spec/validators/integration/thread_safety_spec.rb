# frozen_string_literal: true

require "rails_helper"
require "timeout"

# Active Model builds one validator per class and reuses it for every record and
# every thread, so validators must not keep per-validation state on themselves.
# These examples park one validation inside the shared validator instance, let a
# second one run to completion, then resume the first.
RSpec.describe "Thread safety" do
  let(:model_class) { ContentType::Validator::Check }
  let(:validator) do
    model_class.validators.find do |candidate|
      candidate.is_a?(ActiveStorageValidations::ContentTypeValidator) &&
        candidate.attributes.include?(:with_string)
    end
  end
  let(:record_with_pdf) { model_class.new.tap { |record| record.with_string.attach(pdf_150x150_file) } }
  let(:record_with_jpeg) { model_class.new.tap { |record| record.with_string.attach(file_7ko_and_jpg) } }
  let(:paused) { Queue.new }
  let(:resume) { Queue.new }

  before do
    allow(validator).to receive(:is_valid?).and_wrap_original do |original, *args|
      if args.first.equal?(record_with_pdf)
        paused << true
        resume.pop
      end
      original.call(*args)
    end
  end

  def validate_interleaved
    Timeout.timeout(10) do
      parked = Thread.new { ActiveRecord::Base.connection_pool.with_connection { record_with_pdf.valid? } }
      paused.pop
      Thread.new { ActiveRecord::Base.connection_pool.with_connection { record_with_jpeg.valid? } }.join
      resume << true
      parked.join
    end
  end

  context "when two records are validated concurrently by the same validator" do
    before { validate_interleaved }

    it "reports the parked record's own content type" do
      expect(record_with_pdf.errors.first.options[:content_type]).to eq("application/pdf")
    end

    it "reports the concurrent record's own content type" do
      expect(record_with_jpeg.errors.first.options[:content_type]).to eq("image/jpeg")
    end

    it "leaves no per-validation state on the shared validator" do
      expect(validator.instance_variables).to contain_exactly(:@attributes, :@options)
    end
  end
end
