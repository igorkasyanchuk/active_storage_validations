# frozen_string_literal: true

RSpec.shared_examples "base comparison validator matcher only match when exact value" do
  %w[value proc].each do |value_type|
    describe value_type do
      let(:matcher) { described_class.new(:"#{value_type == 'proc' ? 'proc_' : ''}#{model_attribute}") }
      let(:lower_value) do
        case described_class.name
        when /Size/ then 0.5.kilobyte
        when /Duration/ then 1.second
        when /Pages/ then 1
        end
      end
      let(:higher_value) do
        case described_class.name
        when /Size/ then 99.kilobytes
        when /Duration/ then 99.seconds
        when /Pages/ then 99
        end
      end

      context "when provided with a lower value than the value specified in the model validations" do
        subject(:matcher_with_value) { matcher.public_send(matcher_method, lower_value) }

        it { is_expected_not_to_match_for(klass) }
      end

      context "when provided with the exact value specified in the model validations" do
        subject(:matcher_with_value) { matcher.public_send(matcher_method, validator_value) }

        it { is_expected_to_match_for(klass) }
      end

      context "when provided with a higher value than the value specified in the model validations" do
        subject(:matcher_with_value) { matcher.public_send(matcher_method, higher_value) }

        it { is_expected_not_to_match_for(klass) }
      end
    end
  end
end
