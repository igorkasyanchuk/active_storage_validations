# frozen_string_literal: true

require "test_helper"

describe "Analyzer command timeouts" do
  after do
    ActiveStorageValidations.command_timeout = 10.seconds
  end

  describe ActiveStorageValidations::Analyzer::ContentTypeAnalyzer do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::ContentTypeAnalyzer.new(attachable, timeout: 5.seconds)
    end

    it "returns nil from media_from_path when the command times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_nil analyzer.send(:media_from_path, path)
      end
    end

    it "includes timeout metadata on analyze.active_storage_validations" do
      payloads = []
      subscriber = ActiveSupport::Notifications.subscribe("analyze.active_storage_validations") do |*args|
        payloads << ActiveSupport::Notifications::Event.new(*args).payload
      end

      analyzer.content_type

      payload = payloads.find { |entry| entry[:analyzer] == "file" }
      assert payload
      assert_equal 5.0, payload[:timeout]
      refute payload[:timed_out]
      assert payload.key?(:duration)
      assert payload[:duration] >= 0
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  describe ActiveStorageValidations::Analyzer::PdfAnalyzer do
    let(:path) { Rails.root.join("public", "pdf_150x150.pdf").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "pdf_150x150.pdf",
        content_type: "application/pdf"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::PdfAnalyzer.new(attachable, timeout: 0.2)
    end

    it "returns nil from media_from_path when the command times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_nil analyzer.send(:media_from_path, path)
      end
    end
  end

  describe ActiveStorageValidations::Analyzer::VideoAnalyzer do
    let(:path) { Rails.root.join("public", "video_150x150.mp4").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "video_150x150.mp4",
        content_type: "video/mp4"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::VideoAnalyzer.new(attachable, timeout: 0.2)
    end

    it "returns nil from media_from_path when ffprobe times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_nil analyzer.send(:media_from_path, path)
      end
    end

    it "returns empty metadata when ffprobe times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_equal({}, analyzer.metadata)
      end
    end
  end

  describe ActiveStorageValidations::Analyzer::AudioAnalyzer do
    let(:path) { Rails.root.join("public", "audio_2s.mp3").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "audio_2s.mp3",
        content_type: "audio/mpeg"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::AudioAnalyzer.new(attachable, timeout: 0.2)
    end

    it "returns empty metadata when ffprobe times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_equal({}, analyzer.metadata)
      end
    end
  end

  describe ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::ImageAnalyzer::Vips.new(attachable, timeout: 0.1)
    end

    it "returns empty metadata and emits timeout when the load exceeds the deadline" do
      skip "requires the ruby-vips gem" unless analyzer.send(:supported?)

      release = Queue.new
      events = []
      subscriber = ActiveSupport::Notifications.subscribe("timeout.active_storage_validations") do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      analyzer.stub(:open_vips_image, ->(*) { release.pop; nil }) do
        assert_equal({}, analyzer.metadata)
      end

      assert_equal 1, events.size
      assert_equal "vips", events.first.payload[:command]
      assert_in_delta 0.1, events.first.payload[:timeout], 0.001
    ensure
      release << :done if defined?(release)
      ActiveSupport::Notifications.unsubscribe(subscriber) if defined?(subscriber) && subscriber
    end

    it "returns empty metadata for unsupported files without raising" do
      skip "requires the ruby-vips gem" unless analyzer.send(:supported?)

      analyzer.stub(:open_vips_image, nil) do
        assert_equal({}, analyzer.metadata)
      end
    end
  end

  describe ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick do
    let(:path) { Rails.root.join("public", "image_150x150.png").to_s }
    let(:attachable) do
      {
        io: File.open(path),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end
    let(:analyzer) do
      ActiveStorageValidations::Analyzer::ImageAnalyzer::ImageMagick.new(attachable, timeout: 5.seconds)
    end

    it "returns nil from media_from_path when identify times out" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_nil analyzer.send(:media_from_path, path)
      end
    end

    it "runs identify through run_command" do
      seen_argv = nil
      real_run = analyzer.method(:run_command)

      analyzer.stub(:run_command, ->(*argv, payload: nil) {
        seen_argv = argv
        real_run.call(*argv, payload: payload)
      }) do
        info = analyzer.send(:media_from_path, path)

        assert info.valid?
        assert_equal 150, info.width
        assert_equal 150, info.height
        assert seen_argv.any? { |part| part.to_s.include?("identify") || part.to_s == "magick" }
      end
    end

    it "returns empty metadata when identify times out during metadata" do
      timed_out_result = ActiveStorageValidations::ASVCommandable::CommandResult.new(
        stdout: "",
        stderr: "",
        status: nil,
        timed_out: true
      )

      analyzer.stub(:run_command, timed_out_result) do
        assert_equal({}, analyzer.metadata)
      end
    end

    it "returns empty metadata when identify binary is missing" do
      analyzer.stub(:identify_command, [ "asv_missing_identify_#{Process.pid}", path ]) do
        assert_equal({}, analyzer.metadata)
      end
    end

    describe "#parse_identify_output" do
      it "marks empty stdout as invalid without raising" do
        info = analyzer.send(:parse_identify_output, "")

        refute info.valid?
        assert_equal 0, info.width
        assert_equal 0, info.height
      end

      it "marks garbage stdout as invalid without raising" do
        info = analyzer.send(:parse_identify_output, "not-a-dimension")

        refute info.valid?
      end

      it "uses the first frame of multi-frame identify output" do
        stdout = "150\t150\tUndefined\n300\t200\tRightTop\n"
        info = analyzer.send(:parse_identify_output, stdout)

        assert info.valid?
        assert_equal 150, info.width
        assert_equal 150, info.height
        # Trailing frames leave junk after the first tab-split; rotation must not crash.
        refute analyzer.send(:rotated_image?, info)
      end
    end
  end
end
