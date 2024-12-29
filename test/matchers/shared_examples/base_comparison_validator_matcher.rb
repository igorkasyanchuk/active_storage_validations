module BaseComparisonValidatorMatcher
  module OnlyMatchWhenExactValue
    extend ActiveSupport::Concern

    included do
      %w(value proc).each do |value_type|
        describe value_type do
          let(:matcher_class) { "ActiveStorageValidations::Matchers::#{klass.name.match?(/TotalSize/) ? 'Total' : ''}SizeValidatorMatcher".constantize }
          let(:matcher) { matcher_class.new(:"#{value_type == 'proc' ? 'proc_' : ''}#{model_attribute}") }

          describe 'when provided with a lower size than the size specified in the model validations' do
            subject { matcher.public_send(matcher_method, 0.5.kilobyte) }

            it { is_expected_not_to_match_for(klass) }
          end

          describe 'when provided with the exact size specified in the model validations' do
            subject { matcher.public_send(matcher_method, validator_value) }

            it { is_expected_to_match_for(klass) }
          end

          describe 'when provided with a higher size than the size specified in the model validations' do
            subject { matcher.public_send(matcher_method, 99.kilobytes) }

            it { is_expected_not_to_match_for(klass) }
          end
        end
      end
    end
  end
end
