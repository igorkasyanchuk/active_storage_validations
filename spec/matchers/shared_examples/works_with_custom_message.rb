# frozen_string_literal: true

RSpec.shared_examples "works with custom message" do
  let(:model_attribute) { :with_message }

  context "when provided with the other validator requirements" do
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

    context "and when provided with the model validation message" do
      subject(:configured_matcher) { matcher.with_message("Custom message") }

      it { is_expected_to_match_for(klass) }
    end

    context "and when provided with a different message than the model validation message" do
      subject(:configured_matcher) { matcher.with_message("<wrong message>") }

      it { is_expected_not_to_match_for(klass) }
    end

    context "and when not provided with the #with_message matcher method" do
      subject(:configured_matcher) { matcher }

      it { is_expected_to_match_for(klass) }
    end
  end
end
