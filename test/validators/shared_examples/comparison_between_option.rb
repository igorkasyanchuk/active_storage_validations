# frozen_string_literal: true

module ComparisonBetweenOption
  extend ActiveSupport::Concern

  included do
    let(:validator) { validator_test_class.name.split("::").last.to_sym }

    # validates :between, <validator>: { between: <2 value>..<7 value> }
    # validates :between_proc, <validator>: { between: -> (record) { <2 value>..<7 value> } }
    %w[value proc].each do |value_type|
      describe "#{value_type} validator" do
        describe "when provided with a file with a lower value than the value specified in the model validations" do
          subject { model.between.attach(file_having_lower_than_lower_bound_between_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, with_locales: [ "en" ], error_options: error_options_for_file_having_lower_than_lower_bound_between_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_lower_than_lower_bound_between_option) }
        end

        describe "when provided with a file with the exact lower bound value specified in the model validations" do
          subject { model.between.attach(file_having_exact_lower_bound_between_option) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with a file with a value between the bounds specified in the model validations" do
          subject { model.between.attach(file_having_between_bounds_between_option) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with a file with the exact higher bound value specified in the model validations" do
          subject { model.between.attach(file_having_exact_higher_bound_between_option) and model }

          it { is_expected_to_be_valid }
        end

        describe "when provided with a file with a higher value than the value specified in the model validations" do
          subject { model.between.attach(file_having_higher_than_higher_bound_between_option) and model }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message(error_name, with_locales: [ "en" ], error_options: error_options_for_file_having_higher_than_higher_bound_between_option) }
          it { is_expected_to_have_error_options(error_options_for_file_having_higher_than_higher_bound_between_option) }
        end
      end
    end
  end
end
