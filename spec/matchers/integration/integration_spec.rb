# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Integration tests" do
  let(:klass) { Integration::Matcher }
  let(:matcher_class) { "ActiveStorageValidations::Matchers::#{matcher_type.to_s.camelize}ValidatorMatcher".constantize }
  let(:matcher) { matcher_class.new(model_attribute) }

  describe "example_1" do
    # validates :example_1, size: { less_than: 10.megabytes, message: 'must be less than 10 MB' },
    #                       content_type: ['image/png', 'image/jpeg', 'image/jpeg']
    let(:model_attribute) { :example_1 }

    describe "size matcher" do
      let(:matcher_type) { :size }

      context "when provided with the size value and size message specified in the model validations" do
        subject(:configured_matcher) do
          matcher.less_than(10.megabytes)
          matcher.with_message("must be less than 10 MB")
        end

        it { is_expected_to_match_for(klass) }
      end
    end

    describe "content_type matcher" do
      let(:matcher_type) { :content_type }

      context "when provided with the content_type value specified in the model validations" do
        subject(:configured_matcher) do
          matcher.allowing("image/png", "image/jpeg", "image/jpeg")
        end

        it { is_expected_to_match_for(klass) }
      end
    end
  end

  describe "example_2" do
    let(:model_attribute) { :example_2 }

    describe "aspect_ratio matcher" do
      let(:matcher_type) { :aspect_ratio }

      context "when provided with the aspect_ratio value specified in the model validations" do
        subject(:configured_matcher) do
          matcher.allowing(:square)
        end

        it { is_expected_to_match_for(klass) }
      end
    end

    describe "size matcher" do
      let(:matcher_type) { :size }

      context "when provided with the size value specified in the model validations" do
        subject(:configured_matcher) do
          matcher.less_than_or_equal_to(2.megabytes)
        end

        it { is_expected_to_match_for(klass) }
      end
    end

    describe "content_type matcher" do
      let(:matcher_type) { :content_type }

      context "when provided with the content_type value specified in the model validations" do
        subject(:configured_matcher) do
          matcher.allowing("image/png", "image/jpeg")
        end

        it { is_expected_to_match_for(klass) }
      end
    end

    describe "processable_file matcher" do
      let(:matcher_type) { :processable_file }

      context "when provided with the processable_file value specified in the model validations" do
        subject(:configured_matcher) do
          matcher
        end

        it { is_expected_to_match_for(klass) }
      end
    end
  end

  describe "example_3" do
    # validates :example_3, dimension: { width: { min: 100 } }
    # validates :example_4, dimension: { width: { min: 120 } }
    let(:model_attribute) { :example_3 }
    let(:matcher_type) { :dimension }

    context "when another attachment of the record has no cached metadata yet" do
      subject(:configured_matcher) { matcher.width_min(100) }

      let(:record) do
        klass.create!(example_4: image_150x150_file).tap do |record|
          # Fixtures and uploads made before the validator existed have no asv_* keys.
          record.example_4.blob.remove_active_storage_validations_metadata!
        end
      end

      it "only mocks the analysis of the probe file" do
        expect(configured_matcher.matches?(record)).to be(true)
        expect(record.example_4.blob.reload.active_storage_validations_metadata).not_to include(width: 99)
        expect(klass.find(record.id)).to be_valid
      end
    end
  end
end
