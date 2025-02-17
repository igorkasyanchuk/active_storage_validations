# frozen_string_literal: true

require "test_helper"

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

  describe "mime_type initializers" do
    # This test is linked with:
    # validates :asv_test, content_type: 'application/asv_test'
    # If not working, it would throw an error at the app initialization because
    # of our validator check_validity! method.
    it "allows the developer to define its own custom marcel mime types" do
      assert_equal(Marcel::MimeType.for(declared_type: "application/asv_test"), "application/asv_test")
    end
  end

  describe "working with fixtures" do
    subject { instance.public_send(attribute) && instance }

    let(:attachable) { png_file }

    describe "base case" do
      let(:attribute) { :working_with_fixture }

      it "works fine" do
        subject && assert(subject.valid?)
      end
    end

    describe "with variant" do
      let(:attribute) { :working_with_fixture_and_variant }

      it "works fine" do
        subject && assert(subject.valid?)
      end
    end
  end
end
