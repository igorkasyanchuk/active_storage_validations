# frozen_string_literal: true

module DoesNotWorkWithAllowBlankOption
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::WithAllowBlank.new(params) }

    describe 'when used with :allow_blank option' do
      it do
        is_expected_to_raise_error(
          ArgumentError,
          "You cannot pass the :allow_blank option to the #{validator_test_class.name.delete('::').underscore}"
        )
      end
    end
  end
end
