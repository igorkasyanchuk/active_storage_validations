module ChecksValidatorValidity
  extend ActiveSupport::Concern

  included do
    # Here we do not want to call subject until the test because its initialization
    # will raise an error
    let(:validator_klass) { "ActiveStorageValidations::#{validator_test_class.name.sub(/::/, '')}".constantize }
    let(:not_applicable) { raise ArgumentError, 'Not applicable to this validator'}

    let(:error_message) do
      case validator_klass.to_sym
      when :aspect_ratio then 'You must pass :with to the validator'
      when :attached then not_applicable
      when :content_type then 'You must pass either :with or :in to the validator'
      when :dimension then 'You must pass either :width, :height, :min or :max to the validator'
      when :limit then 'You must pass either :max or :min to the validator'
      when :processable_image then not_applicable
      when :size then 'You must pass either :less_than(_or_equal_to), :greater_than(_or_equal_to), or :between to the validator'
      end
    end

    describe 'when the validator has an invalid check' do
      subject { validator_test_class::CheckValidityInvalidCheck.new(params) }

      it 'raises an error at model initialization' do
        assert_raises(ArgumentError, error_message) { subject }
      end
    end

    describe 'when the validator does not have checks' do
      subject { validator_test_class::CheckValidityNoCheck.new(params) }

      it 'raises an error at model initialization' do
        assert_raises(ArgumentError, error_message) { subject }
      end
    end

    if %i(content_type size).include? module_parent.to_sym
      describe 'when the validator has several checks' do
        subject { validator_test_class::CheckValiditySeveralChecks.new(params) }

        it 'raises an error at model initialization' do
          assert_raises(ArgumentError, error_message) { subject }
        end
      end
    end
  end
end
