module WorksWithCustomMessage
  extend ActiveSupport::Concern

  included do
    let(:model_attribute) { :with_message }

    describe 'when provided with the other validator requirements' do
      before do
        case validator_sym
        when :aspect_ratio then matcher.allowing(:square)
        when :attached then nil
        when :content_type then matcher.allowing('image/png')
        when :dimension then matcher.width(150).height(150)
        when :size then matcher.less_than_or_equal_to(5.megabytes)
        end
      end

      describe 'and when provided with the model validation message' do
        subject { matcher.with_message('Custom message') }

        it { is_expected_to_match_for(klass) }
      end

      describe 'and when provided with a different message than the model validation message' do
        subject { matcher.with_message('<wrong message>') }

        it { is_expected_not_to_match_for(klass) }
      end

      describe 'and when not provided with the #with_message matcher method' do
        subject { matcher }

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
