module WorksWithBothInstanceAndClass
  extend ActiveSupport::Concern

  included do
    describe "when provided with the other validator requirements" do
      before do
        case validator_sym
        when :aspect_ratio then matcher.allowing(:square)
        when :attached then nil
        when :processable_file then nil
        when :limit then matcher.min(1).max(5)
        when :content_type then matcher.allowing("image/png")
        when :dimension then matcher.width(150).height(150)
        when :duration then matcher.less_than_or_equal_to(5.minutes)
        when :size then matcher.less_than_or_equal_to(5.megabytes)
        when :total_size then matcher.less_than_or_equal_to(5.megabytes)
        when :pages then matcher.equal_to(5)
        end
      end

      describe "when the matcher is provided with an instance" do
        subject { matcher }

        let(:model_attribute) { :as_instance }
        let(:instance) { klass.new }

        it { is_expected_to_match_for(instance) }
      end
    end
  end
end
