module BaseComparisonValidatorMatcher
  module OnlyMatchWhenExactValue
    extend ActiveSupport::Concern

    included do
      %w(value proc).each do |value_type|
        describe value_type do
          let(:matcher_class) do
            "ActiveStorageValidations::Matchers::#{klass.name.split('::').first}ValidatorMatcher".constantize
          end
          let(:matcher) { matcher_class.new(:"#{value_type == 'proc' ? 'proc_' : ''}#{model_attribute}") }
          let(:lower_value) do
            case matcher_class.name
            when /Size/ then 0.5.kilobyte
            when /Duration/ then 1.second
            end
          end
          let(:higher_value) do
            case matcher_class.name
            when /Size/ then 99.kilobytes
            when /Duration/ then 99.seconds
            end
          end

          describe 'when provided with a lower value than the value specified in the model validations' do
            subject { matcher.public_send(matcher_method, lower_value) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe 'when provided with the exact value specified in the model validations' do
            subject { matcher.public_send(matcher_method, validator_value) }

            it { is_expected_to_match_for(klass) }
          end

          describe 'when provided with a higher value than the value specified in the model validations' do
            subject { matcher.public_send(matcher_method, higher_value) }

            it { is_expected_not_to_match_for(klass) }
          end
        end
      end
    end
  end
end
