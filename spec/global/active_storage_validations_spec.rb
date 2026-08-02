# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations do
  let(:instance) { ActiveStorageValidations::Check.new }

  it "is part of the app's modules" do
    expect(ActiveStorageValidations).to be_a(Module)
  end

  describe "concerns" do
    subject(:result) { instance.public_send(would_be_overrided_method, attachable) }

    let(:would_be_overrided_method) { :attachable_filename }
    let(:attachable) { png_file }
    let(:expected_clients_method_returned_value) { "client's concern method returned value" }

    it "does not override the app's concerns" do
      expect(subject).to eq(expected_clients_method_returned_value)
    end
  end

  describe "mime_type initializers" do
    # This test is linked with:
    # validates :asv_test, content_type: 'application/asv_test'
    # If not working, it would throw an error at the app initialization because
    # of our validator check_validity! method.
    it "allows the developer to define its own custom marcel mime types" do
      expect(Marcel::MimeType.for(declared_type: "application/asv_test")).to eq("application/asv_test")
    end
  end

  describe "services" do
    # Uncomment this after having uncommented the S3 service in rails_helper.rb
    #
    # describe "digitalocean" do
    #   subject(:result) { instance }
    #
    #   it "works fine with the digitalocean service" do
    #     subject.digitalocean.attach(png_file)
    #   end
    # end
  end
end
