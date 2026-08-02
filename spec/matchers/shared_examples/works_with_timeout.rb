# frozen_string_literal: true

RSpec.shared_examples "works with timeout" do
  let(:model_attribute) { :with_timeout }

  context "when provided with the other validator requirements" do
    before do
      case validator_sym
      when :aspect_ratio then matcher.allowing(:square)
      when :processable_file then nil
      when :content_type then matcher.allowing("image/png")
      when :dimension then matcher.width(150).height(150)
      when :duration then matcher.less_than_or_equal_to(5.minutes)
      when :pages then matcher.equal_to(5)
      end
    end

    context "and when provided with the model validation timeout" do
      subject(:configured_matcher) { matcher.timeout(5.seconds) }

      it { is_expected_to_match_for(klass) }
    end

    context "and when provided with a different timeout than the model validation timeout" do
      subject(:configured_matcher) { matcher.timeout(30.seconds) }

      it { is_expected_not_to_match_for(klass) }
    end

    context "and when not provided with the #timeout matcher method" do
      subject(:configured_matcher) { matcher }

      it { is_expected_to_match_for(klass) }
    end
  end
end
