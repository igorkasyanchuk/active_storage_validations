# frozen_string_literal: true

require 'test_helper'

describe ActiveStorageValidations do
  let(:instance) { ActiveStorageValidations::Check.new }

  it "is part of the app's modules" do
    _(ActiveStorageValidations).must_be_kind_of Module
  end

  describe "concerns" do
    subject { instance.public_send(would_be_overrided_method, attachable) }

    let(:would_be_overrided_method) { :attachable_filename }
    let(:attachable) { png_file }
    let(:expected_clients_method_returned_value) { "client's concern method returned value" }

    it "does not override the app's concerns" do
      assert_equal(subject, expected_clients_method_returned_value)
    end
  end
end
