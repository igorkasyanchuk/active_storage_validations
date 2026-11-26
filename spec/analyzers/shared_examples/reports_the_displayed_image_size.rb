# frozen_string_literal: true

# libvips and ImageMagick must agree on the size of these images.
RSpec.shared_examples "reports the displayed image size" do
  describe "image canvas" do
    subject(:metadata) { analyzer.metadata }

    context "with a GIF whose first frame is smaller than its canvas" do
      let(:attachable) do
        fixture_file("image_100x80_small_first_frame.gif", filename: "image_100x80_small_first_frame.gif", content_type: "image/gif")
      end

      it "returns the canvas size" do
        expect(metadata).to eq({ width: 100, height: 80 })
      end
    end

    # ImageMagick writes this orientation chunk (orNT) when it saves a rotated
    # image as PNG without eXIf; libvips and browsers ignore it.
    context "with a PNG whose only orientation is ImageMagick's private chunk" do
      let(:attachable) do
        fixture_file("image_600x400_imagemagick_orientation_chunk.png", filename: "image_600x400_imagemagick_orientation_chunk.png", content_type: "image/png")
      end

      it "returns the stored size" do
        expect(metadata).to eq({ width: 600, height: 400 })
      end
    end

    # Left by an ImageMagick crop without +repage (vpAg / oFFs chunks).
    context "with a PNG that records a larger virtual canvas" do
      let(:attachable) do
        fixture_file("image_50x40_virtual_canvas_100x80.png", filename: "image_50x40_virtual_canvas_100x80.png", content_type: "image/png")
      end

      it "returns the image size" do
        expect(metadata).to eq({ width: 50, height: 40 })
      end
    end
  end
end
