# frozen_string_literal: true

module ComparisonLessThanOption
  extend ActiveSupport::Concern

  included do
    let(:validator) { validator_test_class.name.split("::").last.to_sym }

    # validates :less_than, <validator>: { less_than: <2 value> }
    # validates :less_than_proc, <validator>: { less_than: -> (record) { <2 value> } }
    %w[value proc].each do |value_type|
      describe "#{value_type} validator" do
        describe "when provided with a file with a lower value than the value specified in the model validations" do
          subject { model.less_than.attach(file_having_lower_than_less_than_option) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with a file with the exact value specified in the model validations" do
          subject { model.less_than.attach(file_having_exact_less_than_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, error_options: error_options_for_file_having_exact_less_than_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_exact_less_than_option) }
        end

        describe "when provided with a file with a higher value than the value specified in the model validations" do
          subject { model.less_than.attach(file_having_higher_than_less_than_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, error_options: error_options_for_file_having_higher_than_less_than_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_higher_than_less_than_option) }
        end
      end
    end
  end
end
