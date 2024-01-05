module WorksWithContext
  extend ActiveSupport::Concern

  included do
    describe 'when the model attribute has a context' do
      describe 'and the matcher is provided with the model attribute validator context' do
        describe 'which is an symbol' do
          subject { matcher.on(:update) }

          let(:model_attribute) { :with_context_symbol }

          it { is_expected_to_match_for(klass) }
        end

        describe 'which is an array' do
          subject { matcher.on(%i[update custom]) }

          let(:model_attribute) { :with_context_array }

          it { is_expected_to_match_for(klass) }
        end
      end

      describe 'and the matcher is provided with a different context than the model attribute validator context' do
        describe 'which is an symbol' do
          subject { matcher.on(:custom2) }

          let(:model_attribute) { :with_context_symbol }

          it { is_expected_to_raise_error(ArgumentError, 'One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute') }
        end

        describe 'which is an array' do
          subject { matcher.on(%i[update custom2]) }

          let(:model_attribute) { :with_context_array }

          it { is_expected_to_raise_error(ArgumentError, 'One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute') }
        end
      end

      describe 'but the matcher is not provided with the #on method' do
        subject { matcher }

        let(:model_attribute) { :with_context_symbol }

        it { is_expected_to_raise_error(ArgumentError, 'This validator matcher needs the #on option to work since its validator has one') }
      end
    end

    describe 'when the model attribute uses an active_storage_validation validator several times' do
      describe 'with several contexts' do
        describe 'and the matcher is provided with' do
          describe 'one of the model attribute validators contexts' do
            subject { matcher.on(:custom) }

            let(:model_attribute) { :with_several_validators_and_contexts }

            it { is_expected_to_match_for(klass) }
          end

          describe 'all of the model attribute validators contexts' do
            subject { matcher.on(%i[update custom]) }

            let(:model_attribute) { :with_several_validators_and_contexts }

            it { is_expected_to_match_for(klass) }
          end

          describe 'one context that is not present in the model attribute validators contexts' do
            subject { matcher.on(:not_present) }

            let(:model_attribute) { :with_several_validators_and_contexts }

            it { is_expected_to_raise_error(ArgumentError, 'One of the provided contexts to the #on method is not found in any of the listed contexts for this attribute') }
          end
        end
      end
    end
  end
end
