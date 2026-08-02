# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::Analyzer::ContentTypeAnalyzer::Magika do
  let(:analyzer) { described_class.new(attachable) }
  let(:attachable) do
    {
      io: File.open(Rails.root.join("public", "image_150x150.png")),
      filename: "image_150x150.png",
      content_type: "image/png"
    }
  end
  let(:magika_json) do
    [
      {
        "path" => "image_150x150.png",
        "result" => {
          "status" => "ok",
          "value" => {
            "output" => {
              "mime_type" => "image/png",
              "label" => "png"
            },
            "score" => 0.99
          }
        }
      }
    ].to_json
  end

  def successful_command_result(stdout)
    ActiveStorageValidations::ASVCommandable::CommandResult.new(
      stdout: stdout,
      stderr: "",
      status: instance_double(Process::Status, success?: true),
      timed_out: false
    )
  end

  describe "#content_type" do
    subject(:content_type) { analyzer.content_type }

    context "when Magika returns a successful JSON payload" do
      before { allow(analyzer).to receive(:run_command).and_return(successful_command_result(magika_json)) }

      it "returns the mime type from Magika JSON output" do
        expect(content_type).to eq({ content_type: "image/png", content_type_backend: "magika" })
      end
    end

    context "when Magika JSON is invalid" do
      before { allow(analyzer).to receive(:run_command).and_return(successful_command_result("not-json")) }

      it "returns nil" do
        expect(content_type).to be_nil
      end
    end

    context "when Magika JSON is an empty array" do
      before { allow(analyzer).to receive(:run_command).and_return(successful_command_result("[]")) }

      it "returns nil" do
        expect(content_type).to be_nil
      end
    end

    context "when Magika JSON is null" do
      before { allow(analyzer).to receive(:run_command).and_return(successful_command_result("null")) }

      it "returns nil" do
        expect(content_type).to be_nil
      end
    end

    context "when the magika command-line tool is not found" do
      before { allow(Process).to receive(:spawn).and_raise(Errno::ENOENT) }

      it "raises an explicit error" do
        expect { content_type }.to raise_error(
          described_class::CommandLineToolNotInstalledError,
          "magika command-line tool is not installed"
        )
      end
    end

    # a-chacon / #404: leading space before %PDF — Magika still sees PDF (unlike file/libmagic)
    describe "PDF with leading whitespace before %PDF", if: magika_cli_available? do
      let(:attachable) { pdf_leading_space_file }

      it "detects application/pdf" do
        expect(content_type).to eq(
          content_type: "application/pdf",
          content_type_backend: "magika"
        )
      end
    end
  end

  describe "timeouts" do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:analyzer) { described_class.new(attachable, timeout: 5.seconds) }

    after { ActiveStorageValidations.command_timeout = 10.seconds }

    context "when the command times out" do
      subject(:media) { analyzer.send(:media_from_path, path) }

      before { allow(analyzer).to receive(:run_command).and_return(timed_out_command_result) }

      it "returns nil from media_from_path" do
        expect(media).to be_nil
      end
    end
  end
end
