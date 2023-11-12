# frozen_string_literal: true

require 'test_helper'
require 'validators/shared_examples/works_with_if_option'
require 'validators/shared_examples/works_with_on_option'

describe ActiveStorageValidations::ProcessableImageValidator do
  include ValidatorHelpers

  let(:params) { {} }

  describe 'Rails options' do
    describe '#if' do
      subject { ProcessableImage::Validator::WithIf.new(params) }

      include WorksWithIfOption
    end

    describe '#on' do
      subject { ProcessableImage::Validator::WithOn.new(params) }

      include WorksWithOnOption
    end
  end
end
