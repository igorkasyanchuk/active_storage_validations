module ChecksIfIsValid
  extend ActiveSupport::Concern

  included do
    describe 'Edge cases' do
      describe 'when the validator is used several times on the same attributes' do
        describe 'and is provided with different error messages' do
          before do
            case validator_sym
            when :aspect_ratio then matcher.allowing(:square)
            when :attached then matcher
            when :content_type then matcher.rejecting('image/jpg')
            when :dimension then matcher.width(150)
            when :size then matcher.less_than(10.megabytes)
            end
          end

          subject { matcher }

          let(:model_attribute) { :validatable_different_error_messages }
          let(:instance) { klass.new(title: "American Psycho") }

          it { is_expected_to_match_for(instance) }
        end
      end
    end
  end
end
