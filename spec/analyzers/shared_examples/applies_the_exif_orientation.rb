# frozen_string_literal: true

RSpec.shared_examples "applies the exif orientation" do
  describe "EXIF orientations" do
    subject(:metadata) { analyzer.metadata }

    # image_700x500_rotated_90.jpg is stored 500x700 with a big-endian
    # Orientation tag, rewritten here to each of the 8 EXIF values.
    let(:stored_jpeg) { File.binread(Rails.root.join("public", "image_700x500_rotated_90.jpg")) }
    let(:orientation_entry) { "\x01\x12\x00\x03\x00\x00\x00\x01".b }
    let(:attachable) do
      jpeg = stored_jpeg.dup
      jpeg[jpeg.index(orientation_entry) + orientation_entry.bytesize, 2] = [ orientation ].pack("n")
      { io: register_fixture_io(StringIO.new(jpeg)), filename: "image.jpg", content_type: "image/jpeg" }
    end

    (1..4).each do |value|
      context "with orientation #{value} (upright or mirrored)" do
        let(:orientation) { value }

        it { expect(metadata).to eq({ width: 500, height: 700 }) }
      end
    end

    (5..8).each do |value|
      context "with orientation #{value} (quarter turn)" do
        let(:orientation) { value }

        it { expect(metadata).to eq({ width: 700, height: 500 }) }
      end
    end

    context "with a TIFF Orientation tag" do
      let(:attachable) do
        fixture_file("image_50x70_rotated_90.tiff", filename: "image_50x70_rotated_90.tiff", content_type: "image/tiff")
      end

      it { expect(metadata).to eq({ width: 50, height: 70 }) }
    end
  end
end
