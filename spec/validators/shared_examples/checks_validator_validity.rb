# frozen_string_literal: true

RSpec.shared_examples "checks validator validity" do
  # Here we do not want to call subject until the test because its initialization
  # will raise an error
  let(:validator_klass) { "ActiveStorageValidations::#{validator_test_class.name.sub(/::/, '')}".constantize }
  let(:not_applicable) { raise ArgumentError, "Not applicable to this validator" }

  let(:error_message) do
    case validator_klass.to_sym
    when :aspect_ratio then "You must pass either :with or :in to the validator"
    when :attached then not_applicable
    when :content_type then "You must pass either :with or :in to the validator"
    when :dimension then "You must pass either :width, :height, :min or :max to the validator"
    when :duration then "You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), :between or :equal_to to the validator"
    when :limit then "You must pass either :max or :min to the validator"
    when :processable_file then not_applicable
    when :size then "You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), :between or :equal_to to the validator"
    when :total_size then "You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), :between or :equal_to to the validator"
    when :pages then "You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), :between or :equal_to to the validator"
    end
  end

  context "when the validator has an invalid check" do
    subject(:model) { validator_test_class::CheckValidityInvalidCheck.new(params) }

    it "raises an error at model initialization" do
      expect { subject }.to raise_error(ArgumentError, error_message)
    end
  end

  context "when the validator does not have checks" do
    subject(:model) { validator_test_class::CheckValidityNoCheck.new(params) }

    it "raises an error at model initialization" do
      expect { subject }.to raise_error(ArgumentError, error_message)
    end
  end

  if %i[content_type size total_size duration pages].include? described_class.to_sym
    context "when the validator has several checks" do
      subject(:model) { validator_test_class::CheckValiditySeveralChecks.new(params) }

      it "raises an error at model initialization" do
        expect { subject }.to raise_error(ArgumentError, error_message)
      end
    end
  end

  if %i[size total_size duration pages].include? described_class.to_sym
    context "when the validator has a :between range missing a bound" do
      subject(:validator) { validator_klass.new(attributes: [ :file ], between: range) }

      let(:bounded_range_error_message) do
        "You must pass a Range with both bounds to :between (use :greater_than_or_equal_to or :less_than_or_equal_to for a single bound)"
      end

      context "when the range is endless (e.g. between: 1.kilobyte..)" do
        let(:range) { 1.. }

        it "raises an error at validator initialization" do
          expect { validator }.to raise_error(ArgumentError, bounded_range_error_message)
        end
      end

      context "when the range is beginless (e.g. between: ..2.megabytes)" do
        let(:range) { ..2 }

        it "raises an error at validator initialization" do
          expect { validator }.to raise_error(ArgumentError, bounded_range_error_message)
        end
      end

      context "when the range is returned by a Proc" do
        let(:range) { ->(_record) { 1.. } }

        it "cannot be checked at validator initialization" do
          expect { validator }.not_to raise_error
        end

        # Range#min / #max raise RangeError on unbounded ranges; error bounds
        # must rely on Range#begin / #end so the record fails validation
        # instead of raising once it is out of range.
        it "still resolves the error bounds without raising" do
          flat_options = validator.send(:set_flat_options, nil)

          expect(validator.send(:min, flat_options)).to eq(1)
          expect(validator.send(:max, flat_options)).to be_nil
        end
      end
    end

    describe "comparison bound validity" do
      subject(:validator) { validator_klass.new(attributes: [ :file ], check => bound) }

      let(:number_error_message) { "You must pass a non-negative number to :#{check} (got #{invalid_bound.inspect})" }
      let(:range_error_message) do
        "You must pass a Range of non-negative numbers, whose begin is not greater than its end, to :between (got #{invalid_bound.inspect})"
      end

      %i[less_than less_than_or_equal_to greater_than greater_than_or_equal_to equal_to].each do |comparison|
        describe ":#{comparison}" do
          let(:check) { comparison }

          [ 0, 2, 1.5 ].each do |valid_bound|
            context "when the bound is #{valid_bound.inspect}" do
              let(:bound) { valid_bound }

              it { expect { validator }.not_to raise_error }
            end
          end

          [ "2MB", -1, nil, 1..2 ].each do |invalid_value|
            context "when the bound is #{invalid_value.inspect}" do
              let(:bound) { invalid_value }
              let(:invalid_bound) { invalid_value }

              it "raises an error at validator initialization" do
                expect { validator }.to raise_error(ArgumentError, number_error_message)
              end
            end
          end

          context "when a Proc returns an invalid bound" do
            let(:bound) { ->(_record) { "2MB" } }

            it "cannot be checked at validator initialization" do
              expect { validator }.not_to raise_error
            end

            it "raises the same error when the Proc is evaluated" do
              expect { validator.send(:set_flat_options, nil) }
                .to raise_error(ArgumentError, "You must pass a non-negative number to :#{check} (got \"2MB\" from a Proc)")
            end
          end

          context "when a Proc returns nil" do
            let(:bound) { ->(_record) { nil } }

            it "sets no bound" do
              expect { validator.send(:set_flat_options, nil) }.not_to raise_error
            end
          end
        end
      end

      describe ":between" do
        let(:check) { :between }

        [ 1..5, 0..0, 1...5 ].each do |valid_range|
          context "when the range is #{valid_range.inspect}" do
            let(:bound) { valid_range }

            it { expect { validator }.not_to raise_error }
          end
        end

        [ 5..1, 3...3, -1..5, "1".."5" ].each do |invalid_range|
          context "when the range is #{invalid_range.inspect}" do
            let(:bound) { invalid_range }
            let(:invalid_bound) { invalid_range }

            it "raises an error at validator initialization" do
              expect { validator }.to raise_error(ArgumentError, range_error_message)
            end
          end
        end

        context "when a Proc returns a reversed range" do
          let(:bound) { ->(_record) { 5..1 } }

          it "raises the same error when the Proc is evaluated" do
            expect { validator.send(:set_flat_options, nil) }.to raise_error(
              ArgumentError,
              "You must pass a Range of non-negative numbers, whose begin is not greater than its end, to :between (got 5..1 from a Proc)"
            )
          end
        end
      end
    end
  end
end
