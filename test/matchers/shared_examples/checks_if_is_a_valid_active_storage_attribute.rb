module ChecksIfIsAValidActiveStorageAttribute
  extend ActiveSupport::Concern

  included do
    describe 'when the passed model attribute' do
      describe 'does not exist' do
        subject { matcher }

        let(:model_attribute) { :not_present_in_model }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'is not an active storage attribute' do
        subject { matcher }

        let(:model_attribute) { :title }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end
end
