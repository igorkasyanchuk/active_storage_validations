module DoesNotWorkWithAllowNilOption
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::WithAllowNil.new(params) }

    describe 'when used with :allow_nil option' do
      it { is_expected_to_raise_error(ArgumentError, "You cannot pass the :allow_nil option to this validator") }
    end
  end
end
