# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/works_with_on_option'

describe ActiveStorageValidations::ContentTypeValidator do
  include ValidatorHelpers

  subject { ContentType::Validator.new(params) }

  let(:params) { {} }

  describe 'Rails options' do
    describe '#on' do
      include WorksWithOnOption
    end
  end
end
