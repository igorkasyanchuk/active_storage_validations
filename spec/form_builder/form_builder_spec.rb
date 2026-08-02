# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::FormBuilder do
  let(:model) { FormBuilder::Check.new }
  let(:builder) { ActionView::Helpers::FormBuilder.new(:check, model, ActionView::Base.empty, {}) }

  describe "#file_field" do
    context "with a content_type validator" do
      context "with a :with symbol option" do
        subject(:html) { builder.file_field(:with_symbol) }

        it "auto-sets accept" do
          expect(html).to include('accept="image/png"')
        end
      end

      context "with an :in array option" do
        subject(:html) { builder.file_field(:in_array) }

        it "auto-sets accept" do
          expect(html).to include("image/png")
          expect(html).to include("image/gif")
        end
      end

      context "with a string MIME type" do
        subject(:html) { builder.file_field(:with_string_mime) }

        it "auto-sets accept" do
          expect(html).to include('accept="image/png"')
        end
      end

      context "with a Regexp content type" do
        subject(:html) { builder.file_field(:with_regex) }

        it "auto-sets accept" do
          expect(html).to include('accept="image/*"')
        end
      end

      context "with a non-matching Regexp option" do
        subject(:html) { builder.file_field(:with_non_matching_regex) }

        it "skips accept gracefully" do
          expect(html).not_to include("accept=")
        end
      end

      context "with a Proc option" do
        subject(:html) { builder.file_field(:with_proc) }

        it "skips accept gracefully" do
          expect(html).not_to include("accept=")
        end
      end

      context "with an explicit accept option" do
        subject(:html) { builder.file_field(:with_symbol, accept: "image/jpeg") }

        it "does not override the explicit accept" do
          expect(html).to include('accept="image/jpeg"')
          expect(html).not_to include("image/png")
        end
      end

      context "with infer_accept: false" do
        subject(:html) { builder.file_field(:with_symbol, infer_accept: false) }

        it "does not set accept" do
          expect(html).not_to include("accept=")
        end
      end

      context "when infer_file_field_accept is disabled globally" do
        around do |example|
          original = ActiveStorageValidations.infer_file_field_accept
          ActiveStorageValidations.infer_file_field_accept = false
          example.run
        ensure
          ActiveStorageValidations.infer_file_field_accept = original
        end

        it "does not set accept" do
          expect(builder.file_field(:with_symbol)).not_to include("accept=")
        end

        context "with infer_accept: true" do
          subject(:html) { builder.file_field(:with_symbol, infer_accept: true) }

          it "overrides the global disable" do
            expect(html).to include('accept="image/png"')
          end
        end
      end
    end

    context "without a content_type validator" do
      subject(:html) { builder.file_field(:no_content_type_validator) }

      it "does not set accept" do
        expect(html).not_to include("accept=")
      end
    end

    context "without any validators" do
      subject(:html) { builder.file_field(:no_validator) }

      it "does not set accept" do
        expect(html).not_to include("accept=")
      end
    end
  end
end
