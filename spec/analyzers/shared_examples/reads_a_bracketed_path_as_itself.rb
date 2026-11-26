# frozen_string_literal: true

# libvips reads `photo.png[0]` as photo.png with loader options, ImageMagick as
# frame 0 of photo.png: a file named like that, next to a photo.png, was
# measured as that sibling.
RSpec.shared_examples "reads a bracketed path as itself" do
  subject(:metadata) { described_class.new(attachable).metadata }

  let(:dir) { Pathname.new(Dir.mktmpdir) }
  let(:path) do
    dir.join("photo.png[0]").tap { |file| FileUtils.cp(Rails.root.join("public", "image_600x800.png"), file) }
  end

  before { FileUtils.cp(Rails.root.join("public", "image_150x150.png"), dir.join("photo.png")) }
  after { FileUtils.rm_rf(dir) }

  context "with a Hash io on that file" do
    let(:attachable) { { io: open_fixture(path, "rb"), filename: "photo.png[0]", content_type: "image/png" } }

    it { expect(metadata).to eq({ width: 600, height: 800 }) }
  end

  # File and Pathname attachables need Rails 7.1.
  if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
    context "with a Pathname" do
      let(:attachable) { path }

      it { expect(metadata).to eq({ width: 600, height: 800 }) }
    end
  end
end
