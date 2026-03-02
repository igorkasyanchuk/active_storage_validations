# frozen_string_literal: true

require "test_helper"

describe ActiveStorageValidations::FormBuilder do
  let(:model) { FormBuilder::Check.new }
  let(:builder) { ActionView::Helpers::FormBuilder.new(:check, model, ActionView::Base.empty, {}) }

  describe "file_field with content_type validator" do
    it "auto-sets accept from :with symbol option" do
      html = builder.file_field(:with_symbol)
      assert_includes html, 'accept="image/png"'
    end

    it "auto-sets accept from :in array option" do
      html = builder.file_field(:in_array)
      assert_includes html, "image/png"
      assert_includes html, "image/gif"
    end

    it "auto-sets accept from string MIME type" do
      html = builder.file_field(:with_string_mime)
      assert_includes html, 'accept="image/png"'
    end

    it "does not override explicit accept option" do
      html = builder.file_field(:with_symbol, accept: "image/jpeg")
      assert_includes html, 'accept="image/jpeg"'
      refute_includes html, "image/png"
    end

    it "handles models without content_type validators" do
      html = builder.file_field(:no_content_type_validator)
      refute_includes html, "accept="
    end

    it "handles attachments with no validators at all" do
      html = builder.file_field(:no_validator)
      refute_includes html, "accept="
    end

    it "skips Proc options gracefully" do
      html = builder.file_field(:with_proc)
      refute_includes html, "accept="
    end

    it "auto-sets accept from Regexp content type" do
      html = builder.file_field(:with_regex)
      assert_includes html, 'accept="image/*"'
    end

    it "skips non-matching Regexp options gracefully" do
      html = builder.file_field(:with_non_matching_regex)
      refute_includes html, "accept="
    end
  end
end
