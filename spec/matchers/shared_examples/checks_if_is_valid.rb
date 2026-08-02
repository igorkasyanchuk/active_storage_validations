# frozen_string_literal: true

RSpec.shared_examples "checks if is valid" do
  describe "Edge cases" do
    context "when the validator is used several times on the same attributes" do
      context "and is provided with different error messages" do
        subject(:configured_matcher) { matcher }

        before do
          case validator_sym
          when :aspect_ratio then matcher.allowing(:square)
          when :attached then matcher
          when :content_type then matcher.rejecting("image/jpg")
          when :processable_file then matcher
          when :limit then matcher.min(1)
          when :dimension then matcher.width(150)
          when :size then matcher.less_than(10.megabytes)
          when :total_size then matcher.less_than(10.megabytes)
          when :pages then matcher.less_than(10)
          end
        end


        let(:model_attribute) { :validatable_different_error_messages }
        let(:instance) { klass.new(title: "American Psycho") }

        it { is_expected_to_match_for(instance) }
      end
    end
  end
end
