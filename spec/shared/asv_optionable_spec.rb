# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::ASVOptionable do
  describe "#set_flat_options" do
    subject(:flat_options) { validator.send(:set_flat_options, record) }

    let(:record) { Size::Validator::Check.new }

    context "with a comparison validator" do
      let(:validator) do
        ActiveStorageValidations::SizeValidator.new(
          attributes: :file,
          less_than: 10.megabytes,
          message: "too big",
          timeout: 2.seconds,
          if: -> { true }
        )
      end

      it "keeps only the validator check options" do
        expect(flat_options).to eq(less_than: 10.megabytes)
      end

      it "leaves Rails and gem configuration options out" do
        expect(flat_options.keys).not_to include(:message, :timeout, :if)
      end
    end

    context "when a check option is a Proc" do
      let(:validator) do
        ActiveStorageValidations::SizeValidator.new(
          attributes: :file,
          less_than: ->(record) { record.class.name.length.megabytes }
        )
      end

      it "resolves the Proc with the record" do
        expect(flat_options).to eq(less_than: Size::Validator::Check.name.length.megabytes)
      end
    end

    context "when a check option is a zero-arity Proc" do
      let(:validator) do
        ActiveStorageValidations::SizeValidator.new(attributes: :file, less_than: -> { 3.megabytes })
      end

      it "calls the Proc without the record" do
        expect(flat_options).to eq(less_than: 3.megabytes)
      end
    end

    context "with nested check options" do
      let(:validator) do
        ActiveStorageValidations::DimensionValidator.new(
          attributes: :file,
          width: { min: ->(_record) { 100 }, max: 200 },
          height: 300,
          message: "wrong dimensions"
        )
      end

      it "flattens the nested Procs and keeps nested check keys" do
        expect(flat_options).to eq(width: { min: 100, max: 200 }, height: 300)
      end

      it "returns fresh hashes rather than the validator options" do
        flat_options[:width][:min] = 0

        expect(validator.options[:width][:min]).to be_a(Proc)
      end
    end

    context "with an Array check option" do
      let(:validator) do
        ActiveStorageValidations::ContentTypeValidator.new(
          attributes: :file,
          in: [ "image/png", ->(_record) { "image/jpeg" } ]
        )
      end

      it "flattens each element" do
        expect(flat_options).to eq(in: [ "image/png", "image/jpeg" ])
      end
    end
  end
end
