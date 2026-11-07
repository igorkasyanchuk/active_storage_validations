# frozen_string_literal: true

RSpec.shared_examples "works with except_on" do
  # Rails :except_on is available since Rails 8.0
  if Rails.gem_version >= Gem::Version.new("8.0.0")
    context "when the model attribute has an except_on context" do
      context "and the matcher is provided with the model attribute validator except_on context" do
        context "which is an symbol" do
          subject(:configured_matcher) { matcher.except_on(:update) }

          let(:model_attribute) { :with_except_on_symbol }

          it { is_expected_to_match_for(klass) }
        end

        context "which is an array" do
          subject(:configured_matcher) { matcher.except_on(%i[update custom]) }

          let(:model_attribute) { :with_except_on_array }

          it { is_expected_to_match_for(klass) }
        end

        # A new record validates in :create, which the validator skips. Each
        # requirement below needs a probe to be rejected, so the matcher only
        # matches when the probes run in a context the validator runs in.
        context "which is :create" do
          subject(:configured_matcher) { matcher.except_on(:create) }

          let(:model_attribute) { :with_except_on_create }

          before do
            case validator_sym
            when :aspect_ratio then matcher.allowing(:square).rejecting(:portrait)
            when :limit then matcher.min(1).max(5)
            when :content_type then matcher.allowing("image/png").rejecting("application/pdf")
            when :dimension then matcher.width(150).height(150)
            when :duration then matcher.less_than_or_equal_to(5.minutes)
            when :size, :total_size then matcher.less_than_or_equal_to(5.megabytes)
            when :pages then matcher.less_than_or_equal_to(5)
            end
          end

          it { is_expected_to_match_for(klass) }
        end
      end

      context "and the matcher is provided with a different context than the model attribute validator except_on context" do
        context "which is an symbol" do
          subject(:configured_matcher) { matcher.except_on(:custom2) }

          let(:model_attribute) { :with_except_on_symbol }

          it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #except_on method is not found in any of the listed contexts for this attribute") }
        end

        context "which is an array" do
          subject(:configured_matcher) { matcher.except_on(%i[update custom2]) }

          let(:model_attribute) { :with_except_on_array }

          it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #except_on method is not found in any of the listed contexts for this attribute") }
        end
      end

      context "but the matcher is not provided with the #except_on method" do
        subject(:configured_matcher) { matcher }

        let(:model_attribute) { :with_except_on_symbol }

        it { is_expected_to_raise_error(ArgumentError, "This validator matcher needs the #except_on option to work since its validator has one") }
      end
    end

    context "when the model attribute uses an active_storage_validation validator several times" do
      context "with several except_on contexts" do
        context "and the matcher is provided with" do
          context "when provided with one of the model attribute validators except_on contexts" do
            subject(:configured_matcher) { matcher.except_on(:custom) }

            let(:model_attribute) { :with_several_validators_and_except_on }

            it { is_expected_to_match_for(klass) }
          end

          context "when provided with all of the model attribute validators except_on contexts" do
            subject(:configured_matcher) { matcher.except_on(%i[update custom]) }

            let(:model_attribute) { :with_several_validators_and_except_on }

            it { is_expected_to_match_for(klass) }
          end

          context "when provided with one context that is not present in the model attribute validators except_on contexts" do
            subject(:configured_matcher) { matcher.except_on(:not_present) }

            let(:model_attribute) { :with_several_validators_and_except_on }

            it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #except_on method is not found in any of the listed contexts for this attribute") }
          end
        end
      end
    end
  end
end
