# frozen_string_literal: true

RSpec.shared_examples "works with context" do
  context "when the model attribute has a context" do
    context "and the matcher is provided with the model attribute validator context" do
      context "which is an symbol" do
        subject(:configured_matcher) { matcher.on(:update) }

        let(:model_attribute) { :with_context_symbol }

        it { is_expected_to_match_for(klass) }
      end

      context "which is an array" do
        subject(:configured_matcher) { matcher.on(%i[update custom]) }

        let(:model_attribute) { :with_context_array }

        it { is_expected_to_match_for(klass) }
      end
    end

    context "and the matcher is provided with a different context than the model attribute validator context" do
      context "which is an symbol" do
        subject(:configured_matcher) { matcher.on(:custom2) }

        let(:model_attribute) { :with_context_symbol }

        it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute") }
      end

      context "which is an array" do
        subject(:configured_matcher) { matcher.on(%i[update custom2]) }

        let(:model_attribute) { :with_context_array }

        it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute") }
      end
    end

    context "but the matcher is not provided with the #on method" do
      subject(:configured_matcher) { matcher }

      let(:model_attribute) { :with_context_symbol }

      it { is_expected_to_raise_error(ArgumentError, "This validator matcher needs the #on option to work since its validator has one") }
    end
  end

  context "when the model attribute uses an active_storage_validation validator several times" do
    context "with several contexts" do
      context "and the matcher is provided with" do
        context "one of the model attribute validators contexts" do
          subject(:configured_matcher) { matcher.on(:custom) }

          let(:model_attribute) { :with_several_validators_and_contexts }

          it { is_expected_to_match_for(klass) }
        end

        context "all of the model attribute validators contexts" do
          subject(:configured_matcher) { matcher.on(%i[update custom]) }

          let(:model_attribute) { :with_several_validators_and_contexts }

          it { is_expected_to_match_for(klass) }
        end

        context "one context that is not present in the model attribute validators contexts" do
          subject(:configured_matcher) { matcher.on(:not_present) }

          let(:model_attribute) { :with_several_validators_and_contexts }

          it { is_expected_to_raise_error(ArgumentError, "One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute") }
        end
      end
    end
  end
end
