# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe ActiveStorageValidations do
  let(:instance) { ActiveStorageValidations::Check.new }

  it "is part of the app's modules" do
    expect(described_class).to be_a(Module)
  end

  # Engine / Railtie subclass Rails::Engine / Rails::Railtie: requiring the gem
  # before Rails (a script, a Bundler.require order) used to raise NameError.
  describe "requiring the gem without Rails loaded" do
    subject(:result) do
      Open3.capture2e(RbConfig.ruby, "-rbundler/setup", "-I", lib_path, "-e", script)
    end

    let(:lib_path) { File.expand_path("../../lib", __dir__) }
    let(:script) do
      <<~RUBY
        require "active_storage_validations"
        print ActiveStorageValidations::Engine.superclass, " ", ActiveStorageValidations::Railtie.superclass
      RUBY
    end

    it "loads the Rails integration it needs" do
      output, status = result

      expect(status).to be_success, output
      expect(output).to eq("Rails::Engine Rails::Railtie")
    end
  end

  describe "concerns" do
    subject(:result) { instance.public_send(would_be_overrided_method, attachable) }

    let(:would_be_overrided_method) { :attachable_filename }
    let(:attachable) { png_file }
    let(:expected_clients_method_returned_value) { "client's concern method returned value" }

    it "does not override the app's concerns" do
      expect(result).to eq(expected_clients_method_returned_value)
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

  # rubocop:disable RSpec/EmptyExampleGroup -- optional S3 integration stub
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
  # rubocop:enable RSpec/EmptyExampleGroup
end
