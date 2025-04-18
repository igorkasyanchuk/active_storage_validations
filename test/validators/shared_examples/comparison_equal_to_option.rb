# frozen_string_literal: true

module ComparisonEqualToOption
  extend ActiveSupport::Concern

  included do
    let(:validator) { validator_test_class.name.split("::").last.to_sym }

    # validates :equal_to, <validator>: { equal_to: <5 value> }
    # validates :equal_to_proc, <validator>: { equal_to: -> (record) { <5 value> } }
    %w[value proc].each do |value_type|
      describe "#{value_type} validator" do
        describe "when provided with a file with a lower value than the value specified in the model validations" do
          subject { model.equal_to.attach(file_having_lower_than_equal_to_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, error_options: error_options_for_file_having_lower_than_equal_to_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_lower_than_equal_to_option) }
        end

        describe "when provided with a file with the exact value specified in the model validations" do
          subject { model.equal_to.attach(file_having_exact_equal_to_option) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with a file with a higher value than the value specified in the model validations" do
          subject { model.equal_to.attach(file_having_higher_than_equal_to_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, error_options: error_options_for_file_having_higher_than_equal_to_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_higher_than_equal_to_option) }
        end
      end
    end
  end
end
