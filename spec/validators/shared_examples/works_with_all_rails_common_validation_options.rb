# frozen_string_literal: true

RSpec.shared_examples "works with all rails common validation options" do
  %i[allow_nil allow_blank if on strict unless message].each do |validation_option|
    describe ":#{validation_option}" do
      it_behaves_like "works with #{validation_option} option"
    end
  end
end
