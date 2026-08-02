# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::LimitValidator do
  let(:validator_test_class) { Limit::Validator }
  let(:params) { {} }

  describe "#check_validity!" do
    it_behaves_like "checks validator validity"

    describe "arguments validity" do
      context "when the passed argument to min or max is not an integer" do
        subject(:model) { validator_test_class::CheckValidityInvalidArgument.new(params) }

        let(:error_message) { "You must pass integers to :min and :max" }

        it "raises an error at model initialization" do
          expect { subject }.to raise_error(ArgumentError, error_message)
        end
      end

      context "when min is higher than max" do
        subject(:model) { validator_test_class::CheckValidityMaxHigherThanMin.new(params) }

        let(:error_message) { "You must pass a higher value to :max than to :min" }

        it "raises an error at model initialization" do
          expect { subject }.to raise_error(ArgumentError, error_message)
        end
      end

      context "when the passed min and/or max are/is a Proc" do
        subject(:model) { validator_test_class::CheckValidityProcOption.new(params) }

        it "does not perform a check, and therefore is valid" do
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  describe "Validator checks" do
    describe ":min" do
      # validates :min, limit: { min: 2 }
      # validates :min_proc, limit: { min: -> (record) { 2 } }
      %w[value proc].each do |value_type|
        describe value_type do
          let(:model) { "#{validator_test_class}::CheckMin#{'Proc' if value_type == 'proc'}".constantize.new(params) }
          let(:attribute) { :"min#{'_proc' if value_type == 'proc'}" }

          context "when provided with a right number of files" do
            subject(:record) { model.public_send(attribute).attach([ file_1, file_2 ]) and model }

            let(:file_1) { png_file }
            let(:file_2) { gif_file }

            it { is_expected_to_be_valid }
          end

          context "when provided with a wrong number of files" do
            subject(:record) { model.public_send(attribute).attach(file_1) and model }

            let(:file_1) { png_file }
            let(:error_options) do
              {
                min: 2,
                max: nil,
                count: 1
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("limit_min_not_reached", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe ":max" do
      # validates :max, limit: { max: 1 }
      # validates :max_proc, limit: { max: -> (record) { 1 } }
      %w[value proc].each do |value_type|
        describe value_type do
          let(:model) { "#{validator_test_class}::CheckMax#{'Proc' if value_type == 'proc'}".constantize.new(params) }
          let(:attribute) { :"max#{'_proc' if value_type == 'proc'}" }

          context "when provided with a right number of files" do
            subject(:record) { model.public_send(attribute).attach(file_1) and model }

            let(:file_1) { png_file }

            it { is_expected_to_be_valid }
          end

          context "when provided with a wrong number of files" do
            subject(:record) { model.public_send(attribute).attach([ file_1, file_2 ]) and model }

            let(:file_1) { png_file }
            let(:file_2) { gif_file }
            let(:error_options) do
              {
                min: nil,
                max: 1,
                count: 2
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("limit_max_exceeded", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe "Combinations" do
      describe ":min + :max" do
        # validates :range, limit: { min: 1, max: 3 }
        # validates :range_proc, limit: { min: -> (record) { 1 }, max: -> (record) { 3 } }
        %w[value proc].each do |value_type|
          describe value_type do
            let(:model) { "#{validator_test_class}::CheckRange#{'Proc' if value_type == 'proc'}".constantize.new(params) }
            let(:attribute) { :"range#{'_proc' if value_type == 'proc'}" }

            context "when provided with a right number of files" do
              subject(:record) { model.public_send(attribute).attach([ file_1, file_2 ]) and model }

              let(:file_1) { png_file }
              let(:file_2) { gif_file }

              it { is_expected_to_be_valid }
            end

            context "when provided with a wrong number of files" do
              context "that is below the lower bound (:max)" do
                subject(:record) { model }


                let(:error_options) do
                  {
                    min: 1,
                    max: 3,
                    count: 0
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("limit_out_of_range", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              context "that is over the upper bound (:max)" do
                subject(:record) { model.public_send(attribute).attach([ file_1, file_1, file_1, file_1 ]) and model }

                let(:file_1) { png_file }
                let(:error_options) do
                  {
                    min: 1,
                    max: 3,
                    count: 4
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("limit_out_of_range", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end
          end
        end
      end
    end
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
