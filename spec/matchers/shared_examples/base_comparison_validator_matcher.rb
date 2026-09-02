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

RSpec.shared_examples "base comparison validator matcher equal_to rejects looser comparisons" do
  context "when the validator uses :less_than_or_equal_to rather than :equal_to" do
    subject(:configured_matcher) { matcher.equal_to(looser_bound) }

    let(:model_attribute) { :less_than_or_equal_to }
    let(:looser_bound) do
      case described_class.name
      when /Size/ then 2.kilobytes
      when /Duration/ then 2.seconds
      when /Pages/ then 2
      end
    end

    it { is_expected_not_to_match_for(klass) }
  end
end

RSpec.shared_examples "base comparison validator matcher less_than_or_equal_to rejects less_than" do
  context "when the validator uses :less_than rather than :less_than_or_equal_to" do
    subject(:configured_matcher) { matcher.less_than_or_equal_to(exclusive_bound) }

    let(:model_attribute) { :less_than }
    let(:exclusive_bound) do
      case described_class.name
      when /Size/ then 2.kilobytes
      when /Duration/ then 2.seconds
      when /Pages/ then 2
      end
    end

    it { is_expected_not_to_match_for(klass) }
  end
end

RSpec.shared_examples "base comparison validator matcher greater_than_or_equal_to rejects greater_than" do
  context "when the validator uses :greater_than rather than :greater_than_or_equal_to" do
    subject(:configured_matcher) { matcher.greater_than_or_equal_to(exclusive_bound) }

    let(:model_attribute) { :greater_than }
    let(:exclusive_bound) do
      case described_class.name
      when /Size/ then 7.kilobytes
      when /Duration/ then 7.seconds
      when /Pages/ then 7
      end
    end

    it { is_expected_not_to_match_for(klass) }
  end
end
