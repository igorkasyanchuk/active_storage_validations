# frozen_string_literal: true

RSpec.shared_examples "does not work with allow_nil option" do
  subject(:model) { validator_test_class::WithAllowNil.new(params) }

  context "when used with :allow_nil option" do
    it do
      is_expected_to_raise_error(
        ArgumentError,
        "You cannot pass the :allow_nil option to the #{validator_test_class.name.delete('::').underscore.split('_').join(' ')}"
      )
    end
  end
end
