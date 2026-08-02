# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers::ContentTypeValidatorMatcher do
  let(:klass) { ContentType::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"


  describe "#validate_content_type_of" do
    it_behaves_like "has custom matcher"
  end

  describe "#allowing" do
    describe "one" do
      let(:model_attribute) { :allowing_one }
      let(:allowed_type) { "image/png" }

      context "when provided with the allowed type" do
        subject(:configured_matcher) { matcher.allowing(allowed_type) }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with something that is not a valid type" do
        subject(:configured_matcher) { matcher.allowing(not_valid_type) }

        let(:not_valid_type) { "not_valid" }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe "several" do
      let(:model_attribute) { :allowing_several }
      let(:allowed_types) { [ "image/png", "image/gif" ] }
      let(:not_allowed_types) { [ "video/x-matroska", "application/pdf" ] }

      describe "usage" do
        describe "splatting the array" do
          subject(:configured_matcher) { matcher.allowing(*allowed_types) }

          it { is_expected_to_match_for(klass) }
        end

        describe "passing the array" do
          subject(:configured_matcher) { matcher.allowing(allowed_types) }

          it { is_expected_to_match_for(klass) }
        end
      end

      context "when provided with the allowed types" do
        subject(:configured_matcher) { matcher.allowing(*allowed_types) }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with only allowed types but not all types" do
        subject(:configured_matcher) { matcher.allowing(allowed_types.sample) }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with allowed and not allowed types" do
        subject(:configured_matcher) { matcher.allowing(allowed_types.sample, not_allowed_types.sample) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with only not allowed types" do
        subject(:configured_matcher) { matcher.allowing(*not_allowed_types) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with something that is not a valid type" do
        subject(:configured_matcher) { matcher.allowing(not_valid_type) }

        let(:not_valid_type) { "not_valid" }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe "several through regex" do
      let(:model_attribute) { :allowing_several_through_regex }
      let(:some_allowed_types) { [ "image/png", "image/gif" ] }
      let(:not_allowed_types) { [ "video/x-matroska", "application/pdf" ] }

      context "when provided with only allowed types but not all types" do
        subject(:configured_matcher) { matcher.allowing(*some_allowed_types) }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with allowed and not allowed types" do
        subject(:configured_matcher) { matcher.allowing(some_allowed_types.sample, not_allowed_types.sample) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with only not allowed types" do
        subject(:configured_matcher) { matcher.allowing(*not_allowed_types) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with something that is not a valid type" do
        subject(:configured_matcher) { matcher.allowing(not_valid_type) }

        let(:not_valid_type) { "not_valid" }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe "Edge cases" do
      context "when the passed content_type is a symbol (e.g. :png)" do
        let(:model_attribute) { :allowing_symbol }
        let(:allowed_type) { :png }

        context "when provided with the allowed type" do
          subject(:configured_matcher) { matcher.allowing(allowed_type) }

          it { is_expected_to_match_for(klass) }
        end
      end

      context "when the content_type specifier (e.g. 'svg+xml') is not strictly equal to the file extension (e.g. '.svg')" do
        let(:model_attribute) { :allowing_sneaky_edge_cases }
        let(:allowed_types) { [ "image/svg+xml", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ] }

        context "when provided with the allowed types" do
          subject(:configured_matcher) { matcher.allowing(*allowed_types) }

          it { is_expected_to_match_for(klass) }
        end
      end
    end
  end

  describe "#rejecting" do
    let(:model_attribute) { :allowing_one }
    let(:allowed_type) { "image/png" }

    describe "one" do
      context "when provided with the allowed type" do
        subject(:configured_matcher) { matcher.rejecting(allowed_type) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with any type but the allowed type" do
        subject(:configured_matcher) { matcher.rejecting(any_type) }

        let(:any_type) { "video/x-matroska" }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with something that is not a valid type" do
        subject(:configured_matcher) { matcher.rejecting(not_valid_type) }

        let(:not_valid_type) { "not_valid" }

        it { is_expected_to_match_for(klass) }
      end
    end

    describe "several" do
      describe "usage" do
        let(:any_types) { [ "video/x-matroska", "image/gif" ] }

        describe "splatting the array" do
          subject(:configured_matcher) { matcher.rejecting(*any_types) }

          it { is_expected_to_match_for(klass) }
        end

        describe "passing the array" do
          subject(:configured_matcher) { matcher.rejecting(any_types) }

          it { is_expected_to_match_for(klass) }
        end
      end

      context "when provided with any types but the allowed type" do
        subject(:configured_matcher) { matcher.rejecting(*any_types) }

        let(:any_types) { [ "video/x-matroska", "image/gif" ] }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with any types and the allowed type" do
        subject(:configured_matcher) { matcher.rejecting(*types) }

        let(:any_types) { [ "video/x-matroska", "image/gif" ] }
        let(:types) { any_types + [ allowed_type ] }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  describe "#allow_blank" do
    it_behaves_like "works with allow_blank"
  end

  describe "#with_message" do
    it_behaves_like "works with custom message"
  end

  describe "#on" do
    it_behaves_like "works with context"
  end

  describe "#except_on" do
    it_behaves_like "works with except_on"
  end

  describe "Combinations" do
    describe "#allowing + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_type) { "application/pdf" }

      context "when provided with the allowed type" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.allowing(allowed_type)
            matcher.with_message("Not authorized file type.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#rejecting + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:not_allowed_type) { "video/x-matroska" }

      context "when provided with a not allowed type" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.rejecting(not_allowed_type)
            matcher.with_message("Not authorized file type.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#allowing + #rejecting" do
      let(:model_attribute) { :allowing_one }
      let(:allowed_type) { "image/png" }
      let(:not_allowed_type) { "video/x-matroska" }

      context "when provided with the allowed type" do
        context "and when provided with a not allowed type specified in the model validations" do
          subject(:configured_matcher) do
            matcher.allowing(allowed_type)
            matcher.rejecting(not_allowed_type)
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#allowing + #rejecting + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_type) { "application/pdf" }
      let(:not_allowed_type) { "video/x-matroska" }

      context "when provided with the allowed type" do
        context "and when provided with a not allowed type" do
          context "and when provided with the message specified in the model validations" do
            subject(:configured_matcher) do
              matcher.allowing(allowed_type)
              matcher.rejecting(not_allowed_type)
              matcher.with_message("Not authorized file type.")
            end

            it { is_expected_to_match_for(klass) }
          end
        end
      end
    end
  end

  describe "working with most common mime types" do
    most_common_mime_types.each do |common_mime_type|
      describe "'#{common_mime_type[:mime_type]}' file (.#{common_mime_type[:extension]})" do
        subject(:configured_matcher) { matcher.allowing(allowed_type) }

        let(:allowed_type) { common_mime_type[:mime_type] }
        let(:media) { common_mime_type[:mime_type].split("/").first }
        let(:content) { common_mime_type[:extension].underscore }

        let(:model_attribute) { [ media, content ].join("_") } # e.g. image_jpeg

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
