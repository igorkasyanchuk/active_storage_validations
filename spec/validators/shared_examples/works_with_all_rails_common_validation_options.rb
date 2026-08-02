# frozen_string_literal: true

RSpec.shared_examples "works with all rails common validation options" do
  %i[allow_nil allow_blank if on strict unless message].each do |validation_option|
    describe ":#{validation_option}" do
      it_behaves_like "works with #{validation_option} option"
    end
  end

  # Rails :except_on is available since Rails 8.0
  if Rails.gem_version >= Gem::Version.new("8.0.0")
    describe ":except_on" do
      it_behaves_like "works with except_on option"
    end
  end
end
