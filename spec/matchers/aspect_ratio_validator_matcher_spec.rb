# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Matchers::AspectRatioValidatorMatcher do
  let(:klass) { AspectRatio::Matcher }
  let(:matcher) { described_class.new(model_attribute) }

  it_behaves_like "checks if is a valid active storage attribute"
  it_behaves_like "checks if is valid"
  it_behaves_like "has custom matcher"
  it_behaves_like "has valid rspec message methods"
  it_behaves_like "works with both instance and class"


  describe "#validate_aspect_ratio_of" do
    it_behaves_like "has custom matcher"
  end

  describe "#allowing" do
    describe "one" do
      describe "named aspect ratio" do
        ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
          describe ":#{aspect_ratio}" do
            let(:model_attribute) { :"allowing_one_#{aspect_ratio}" }
            let(:allowed_aspect_ratio) { aspect_ratio }

            context "when provided with the exact named allowed aspect ratio" do
              subject(:configured_matcher) { matcher.allowing(allowed_aspect_ratio) }

              it { is_expected_to_match_for(klass) }
            end

            context "when provided with a 'is_x_y' aspect ratio" do
              context "that fits the named aspect ratio constraint" do
                subject(:configured_matcher) { matcher.allowing(matching_is_x_y_aspect_ratio) }

                let(:matching_is_x_y_aspect_ratio) do
                  case aspect_ratio
                  when :square then :is_2_2
                  when :portrait then :is_4_5
                  when :landscape then :is_16_9
                  end
                end

                it { is_expected_to_match_for(klass) }
              end

              context "that does not fit the named aspect ratio constraint" do
                subject(:configured_matcher) { matcher.allowing(not_matching_is_x_y_aspect_ratio) }

                let(:not_matching_is_x_y_aspect_ratio) do
                  case aspect_ratio
                  when :square then :is_16_9
                  when :portrait then :is_2_2
                  when :landscape then :is_4_5
                  end
                end

                it { is_expected_not_to_match_for(klass) }
              end
            end

            context "when provided with any aspect ratio but the named allowed aspect ratio" do
              subject(:configured_matcher) { matcher.allowing(any_aspect_ratio) }

              let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS - [ aspect_ratio ]).sample }

              it { is_expected_not_to_match_for(klass) }
            end

            context "when provided with something that is not a valid named aspect ratio" do
              subject(:configured_matcher) { matcher.allowing(not_valid_aspect_ratio) }

              let(:not_valid_aspect_ratio) { :not_valid }

              it { is_expected_not_to_match_for(klass) }
            end
          end
        end
      end

      describe "'is_x_y' aspect ratio" do
        let(:model_attribute) { :allowing_one_is_x_y }

        context "when provided with a regex compatible aspect ratio" do
          subject(:configured_matcher) { matcher.allowing(allowed_aspect_ratio) }

          let(:allowed_aspect_ratio) { :is_16_9 }

          it { is_expected_to_match_for(klass) }
        end

        context "when provided with something that is not a valid aspect ratio" do
          subject(:configured_matcher) { matcher.allowing(not_valid_aspect_ratio) }

          let(:not_valid_aspect_ratio) { :is_16 }

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end

    describe "several" do
      context "when all specified aspect ratios exactly match the allowed list" do
        subject(:configured_matcher) { matcher.allowing(:portrait, :square) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_to_match_for(klass) }
      end

      context "when some specified aspect ratios match but not all" do
        subject(:configured_matcher) { matcher.allowing(:landscape, :square) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_not_to_match_for(klass) }
      end

      context "when none of the specified aspect ratios match" do
        subject(:configured_matcher) { matcher.allowing(:landscape, :is_4_3) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  describe "#rejecting" do
    describe "one" do
      describe "named aspect ratio" do
        ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS.each do |aspect_ratio|
          describe ":#{aspect_ratio}" do
            let(:model_attribute) { :"allowing_one_#{aspect_ratio}" }
            let(:allowed_aspect_ratio) { aspect_ratio }

            context "when provided with the allowed named aspect ratio" do
              subject(:configured_matcher) { matcher.rejecting(allowed_aspect_ratio) }

              it { is_expected_not_to_match_for(klass) }
            end

            context "when provided with any aspect ratio but the allowed named aspect ratio" do
              subject(:configured_matcher) { matcher.rejecting(any_aspect_ratio) }

              let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS - [ aspect_ratio ]).sample }

              it { is_expected_to_match_for(klass) }
            end

            context "when provided with something that is not a valid named aspect ratio" do
              subject(:configured_matcher) { matcher.rejecting(not_valid_aspect_ratio) }

              let(:not_valid_aspect_ratio) { "not_valid" }

              it { is_expected_to_match_for(klass) }
            end
          end
        end
      end

      describe "'is_x_y' aspect ratio" do
        let(:model_attribute) { :allowing_one_is_x_y }

        context "when provided with the allowed aspect ratio" do
          subject(:configured_matcher) { matcher.rejecting(allowed_aspect_ratio) }

          let(:allowed_aspect_ratio) { :is_16_9 }

          it { is_expected_not_to_match_for(klass) }
        end

        context "when provided with any aspect ratio but the allowed aspect ratio" do
          subject(:configured_matcher) { matcher.rejecting(any_aspect_ratio) }

          let(:any_aspect_ratio) { (ActiveStorageValidations::AspectRatioValidator::NAMED_ASPECT_RATIOS + [ :is_4_5 ]).sample }

          it { is_expected_to_match_for(klass) }
        end

        context "when provided with something that is not a valid aspect ratio" do
          subject(:configured_matcher) { matcher.allowing(not_valid_aspect_ratio) }

          let(:not_valid_aspect_ratio) { "not_valid" }

          it { is_expected_not_to_match_for(klass) }
        end
      end
    end

    describe "several" do
      context "when rejecting aspect ratios that are not in the allowed list" do
        subject(:configured_matcher) { matcher.rejecting(:is_16_9, :landscape) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_to_match_for(klass) }
      end

      context "when rejecting some aspect ratios that overlap with the allowed list" do
        subject(:configured_matcher) { matcher.rejecting(:landscape, :square) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_not_to_match_for(klass) }
      end

      context "when rejecting aspect ratios that are in the allowed list" do
        subject(:configured_matcher) { matcher.rejecting(:square, :portrait) }

        let(:model_attribute) { :allowing_several }


        it { is_expected_not_to_match_for(klass) }
      end
    end
  end

  describe "Combinations" do
    describe "#allowing + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_aspect_ratio) { :portrait }

      context "when provided with the allowed type" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.allowing(allowed_aspect_ratio)
            matcher.with_message("Not authorized aspect ratio.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#rejecting + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:not_allowed_aspect_ratio) { :square }

      context "when provided with a not allowed aspect ratio" do
        context "and when provided with the message specified in the model validations" do
          subject(:configured_matcher) do
            matcher.rejecting(not_allowed_aspect_ratio)
            matcher.with_message("Not authorized aspect ratio.")
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#allowing + #rejecting" do
      let(:model_attribute) { :allowing_one_square }
      let(:allowed_aspect_ratio) { :square }
      let(:not_allowed_aspect_ratio) { :portrait }

      context "when provided with the allowed aspect ratio" do
        context "and when provided with a not allowed aspect ratio specified in the model validations" do
          subject(:configured_matcher) do
            matcher.allowing(allowed_aspect_ratio)
            matcher.rejecting(not_allowed_aspect_ratio)
          end

          it { is_expected_to_match_for(klass) }
        end
      end
    end

    describe "#allowing + #rejecting + #with_message" do
      let(:model_attribute) { :allowing_one_with_message }
      let(:allowed_aspect_ratio) { :portrait }
      let(:not_allowed_aspect_ratio) { :landscape }

      context "when provided with the allowed aspect ratio" do
        context "and when provided with a not allowed aspect ratio" do
          context "and when provided with the message specified in the model validations" do
            subject(:configured_matcher) do
              matcher.allowing(allowed_aspect_ratio)
              matcher.rejecting(not_allowed_aspect_ratio)
              matcher.with_message("Not authorized aspect ratio.")
            end

            it { is_expected_to_match_for(klass) }
          end
        end
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
end
