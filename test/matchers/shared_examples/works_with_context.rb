module WorksWithContext
  extend ActiveSupport::Concern

  included do
    describe 'when provided with the model validation context' do
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

    describe 'when provided with a different context than the model validation context' do
      describe 'which is an symbol' do
        subject { matcher.on(:custom2) }

        let(:model_attribute) { :with_context_symbol }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'which is an array' do
        subject { matcher.on(%i[update custom2]) }

        let(:model_attribute) { :with_context_array }

        it { is_expected_not_to_match_for(klass) }
      end
    end

    describe 'when not provided with the #on matcher method' do
      subject { matcher }

      let(:model_attribute) { :with_context_symbol }

      it { is_expected_to_raise_error(ArgumentError, 'This validator matcher needs the #on option to work since its validator has one') }
    end
  end
end
