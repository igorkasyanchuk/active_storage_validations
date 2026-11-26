# frozen_string_literal: true

require "rails_helper"

# `message: :key` is looked up by Rails with the Symbol in place of the error
# type. Its placeholders that an error does not carry raised
# I18n::MissingInterpolationArgument from errors.full_messages.
RSpec.describe ActiveStorageValidations::ASVErrorable do
  subject(:record) { klass.new.tap { |model| model.avatar.attach(attachable) } }

  around do |example|
    I18n.backend.store_translations(:en, errors: { messages: {
      asv_spec_too_narrow: "must be at least %{length}px wide",
      asv_spec_wrong_type: "is a %{detected_human_content_type} file"
    } })
    I18n.backend.store_translations(:fr, errors: { messages: { asv_spec_too_narrow: "doit faire au moins %{length}px (%{width})" } })
    example.run
  end

  context "with a dimension message on a file that cannot be analyzed" do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = "dimension_validator_checks"
        def self.name = "CustomSymbolMessageDimension"
        has_one_attached :avatar
        validates :avatar, dimension: { width: { min: 100 }, message: :asv_spec_too_narrow }
      end
    end
    let(:attachable) { empty_io_file }

    it "leaves the missing value blank instead of raising" do
      record.valid?

      expect(record.errors.full_messages).to eq([ "Avatar must be at least px wide" ])
    end

    it "also blanks the values only another locale uses" do
      record.valid?

      I18n.with_locale(:fr) { expect { record.errors.full_messages }.not_to raise_error }
    end
  end

  context "with a content_type message using a spoofing value on a type error" do
    let(:klass) do
      Class.new(ApplicationRecord) do
        self.table_name = "content_type_validator_checks"
        def self.name = "CustomSymbolMessageContentType"
        has_one_attached :avatar
        validates :avatar, content_type: { with: :png, message: :asv_spec_wrong_type }
      end
    end
    let(:attachable) { pdf_file }

    it "leaves the missing value blank instead of raising" do
      record.valid?

      expect(record.errors.full_messages).to eq([ "Avatar is a  file" ])
    end
  end
end
