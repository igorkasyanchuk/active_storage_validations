# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers do
  describe ".stub_method" do
    describe "an instance method" do
      subject(:stubbed_size) do
        described_class.stub_method(io, :size, 123) { io.size }
      end

      let(:io) { Tempfile.new("stub_method") }

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
end
