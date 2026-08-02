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

  if %i[content_type size total_size].include? described_class.to_sym
    context "when the validator has several checks" do
      subject(:model) { validator_test_class::CheckValiditySeveralChecks.new(params) }

      it "raises an error at model initialization" do
        expect { subject }.to raise_error(ArgumentError, error_message)
      end
    end
  end
end
