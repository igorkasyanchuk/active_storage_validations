module WorksWithAllowBlank
  extend ActiveSupport::Concern

  included do
    let(:model_attribute) { :allow_blank }

    describe 'when provided with the other validator requirements' do
      before do
        case validator_sym
        when :aspect_ratio then matcher.allowing(:square)
        when :content_type then matcher.allowing('image/png')
        when :dimension then matcher.width(150).height(150)
        when :size then matcher.less_than_or_equal_to(5.megabytes)
        end
      end

      describe 'and when provided with #allow_blank method' do
        subject { matcher.allow_blank }

        it { is_expected_to_match_for(klass) }
      end

      describe 'and when not provided with #allow_blank method' do
        subject { matcher }

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
