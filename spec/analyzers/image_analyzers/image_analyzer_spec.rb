# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Analyzer::ImageAnalyzer do
  describe "support cache" do
    let(:analyzer_class) do
      Class.new(described_class) do
        def supported?
          true
        end
      end
    end
    let(:attachable) { "unused" }

    around do |example|
      described_class.reset_supported_analyzers_cache!
      example.run
      described_class.reset_supported_analyzers_cache!
    end

    it "calls supported? once per analyzer class" do
      first = analyzer_class.new(attachable)
      second = analyzer_class.new(attachable)

      allow(first).to receive(:supported?).and_call_original
      allow(second).to receive(:supported?).and_call_original

      first.send(:analyzer_supported?)
      second.send(:analyzer_supported?)

      expect(first).to have_received(:supported?).once
      expect(second).not_to have_received(:supported?)
    end

    it "does not share the cached result across analyzer classes" do
      other_class = Class.new(described_class) do
        def supported?
          false
        end
      end

      expect(analyzer_class.new(attachable).send(:analyzer_supported?)).to be(true)
      expect(other_class.new(attachable).send(:analyzer_supported?)).to be(false)
    end
  end
end
