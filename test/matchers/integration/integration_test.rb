# frozen_string_literal: true

require 'test_helper'

describe 'Integration tests' do
  include MatcherHelpers

  let(:klass) { Integration::Matcher }
  let(:matcher_class) { "ActiveStorageValidations::Matchers::#{matcher_type.to_s.camelize}ValidatorMatcher".constantize }
  let(:matcher) { matcher_class.new(model_attribute) }

  describe 'example_1' do
    # validates :example_1, size: { less_than: 10.megabytes, message: 'must be less than 10 MB' },
    #                       content_type: ['image/png', 'image/jpeg', 'image/jpeg']
    let(:model_attribute) { :example_1 }

    describe 'size matcher' do
      let(:matcher_type) { :size }

      describe 'when provided with the size value and size message specified in the model validations' do
        subject do
          matcher.less_than(10.megabytes)
          matcher.with_message('must be less than 10 MB')
        end

        it { is_expected_to_match_for(klass) }
      end
    end

    describe 'content_type matcher' do
      let(:matcher_type) { :content_type }

      describe 'when provided with the content_type value specified in the model validations' do
        subject do
          matcher.allowing('image/png', 'image/jpeg', 'image/jpeg')
        end

        it { is_expected_to_match_for(klass) }
      end
    end
  end
end
