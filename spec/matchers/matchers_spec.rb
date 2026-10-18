# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers do
  describe ".stub_method" do
    describe "an instance method" do
      subject(:stubbed_size) do
        described_class.stub_method(io, :size, 123) { io.size }
      end

      let(:io) { register_fixture_io(Tempfile.new("stub_method")) }

      after { io.close! }

      it "returns the stubbed value" do
        expect(stubbed_size).to eq(123)
      end

      it "restores the original method after the block" do
        described_class.stub_method(io, :size, 123) { io.size }

        expect(io.size).to eq(0)
      end

      context "when the block raises" do
        subject(:stub_and_raise) do
          described_class.stub_method(io, :size, 123) { raise "boom" }
        end

        it "restores the original method" do
          expect { stub_and_raise }.to raise_error(RuntimeError, "boom")
          expect(io.size).to eq(0)
        end
      end
    end

    describe "a class method inherited by subclasses" do
      subject(:stubbed_instances) do
        described_class.stub_method(parent, :new, stubbed) do
          [ parent.new, child.new("ignored", timeout: 1) ]
        end
      end

      let(:parent) do
        Class.new do
          def initialize(*); end
        end
      end
      let(:child) { Class.new(parent) }
      let(:stubbed) { Object.new }

      it "returns the stubbed value for the parent and subclasses" do
        expect(stubbed_instances).to eq([ stubbed, stubbed ])
      end

      it "restores inherited .new after the block" do
        described_class.stub_method(parent, :new, stubbed) { parent.new }

        expect(parent.new).to be_a(parent)
        expect(child.new).to be_a(child)
      end
    end

    describe "a method already defined on the singleton class" do
      subject(:stubbed_value) do
        described_class.stub_method(object, :custom, :stubbed) { object.custom }
      end

      let(:object) do
        Object.new.tap do |instance|
          def instance.custom
            :original
          end
        end
      end

      it "returns the stubbed value" do
        expect(stubbed_value).to eq(:stubbed)
      end

      it "restores the singleton method after the block" do
        described_class.stub_method(object, :custom, :stubbed) { object.custom }

        expect(object.custom).to eq(:original)
      end
    end
  end

  describe ".mock_metadata" do
    let(:analyzer_class) { ActiveStorageValidations::Analyzer::NullAnalyzer }
    let(:attachable) { { io: StringIO.new, filename: "test.png", content_type: "image/png" } }

    def mocked_metadata(&block)
      described_class.mock_metadata(attachable, { width: 10 }, &block)
    end

    it "mocks every analyzer within the block" do
      metadata = mocked_metadata { analyzer_class.new(attachable).metadata }

      expect(metadata).to include(width: 10)
    end

    it "restores the analyzers after the block" do
      mocked_metadata { nil }

      expect(analyzer_class.new(attachable)).to be_a(analyzer_class)
    end

    it "does not mock analyzers in other threads" do
      analyzer = mocked_metadata { Thread.new { analyzer_class.new(attachable) }.value }

      expect(analyzer).to be_a(analyzer_class)
    end

    # Thread A enters, thread B enters, A leaves, B leaves: B must still see
    # its own mock after A leaves, and nothing may stay mocked afterwards.
    def overlapping_mocked_metadata
      a_entered, a_left, b_entered = Array.new(3) { Queue.new }
      thread_a = Thread.new do
        described_class.mock_metadata(attachable, { width: 1 }) { a_entered << true && b_entered.pop }
        a_left << true
      end
      thread_b = Thread.new do
        a_entered.pop
        described_class.mock_metadata(attachable, { width: 2 }) do
          b_entered << true && a_left.pop
          analyzer_class.new(attachable).metadata
        end
      end
      thread_b.value.tap { thread_a.join }
    end

    it "isolates overlapping blocks in different threads" do
      expect(overlapping_mocked_metadata).to include(width: 2)
      expect(analyzer_class.new(attachable)).to be_a(analyzer_class)
    end
  end
end
