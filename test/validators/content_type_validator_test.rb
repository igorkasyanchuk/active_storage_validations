# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/works_with_if_option'
require 'validators/shared_examples/works_with_on_option'

describe ActiveStorageValidations::ContentTypeValidator do
  include ValidatorHelpers

  let(:params) { {} }

  describe 'Rails options' do
    describe '#if' do
      subject { ContentType::Validator::WithIf.new(params) }

      include WorksWithIfOption
    end

    describe '#on' do
      subject { ContentType::Validator::WithOn.new(params) }

      include WorksWithOnOption
    end
  end
end
