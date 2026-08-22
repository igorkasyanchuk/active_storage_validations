# frozen_string_literal: true

RSpec.shared_examples "ASVErrorable" do
  subject(:model) { validator_test_class::AsvErrorable.new(params) }

  let(:file_not_matching_requirements) do
    case validator_sym
    when :aspect_ratio then image_700x500_file
    when :content_type then html_file
    when :dimension then image_700x500_file
    when :duration then audio_5s
    when :with_audio then video_file
    when :processable_file then tar_file_with_image_content_type
    when :size then file_5ko
    when :pages then pdf_7_pages_file
    end
  end
  let(:source_path) { file_not_matching_requirements[:io].path }
  let(:declared_filename) { file_not_matching_requirements[:filename] }
  let(:path_filename) { File.basename(source_path) }
  let(:error_options) { { filename: expected_filename } }

  # As stated in ActiveStorage documentation, attachables can either be a:
  #   ActiveStorage::Blob object
  #   ActionDispatch::Http::UploadedFile object
  #   Rack::Test::UploadedFile object
  #   Hash object representing the io / filename / content_type
  #   String object representing the signed reference to blob
  #   File object
  #   Pathname object

  describe "Hash object representing the io / filename / content_type" do
    before { model.asv_errorable.attach(attachable) }

    let(:attachable) { file_not_matching_requirements }
    let(:expected_filename) { declared_filename }

    it { is_expected_not_to_be_valid(context: :create) }
    it { is_expected_to_have_error_options(error_options, context: :create) }
  end

  describe "ActionDispatch::Http::UploadedFile object" do
    before { model.asv_errorable.attach(attachable) }

    let(:attachable) { uploaded_file_from(file_not_matching_requirements) }
    let(:expected_filename) { declared_filename }

    it { is_expected_not_to_be_valid(context: :create) }
    it { is_expected_to_have_error_options(error_options, context: :create) }
  end

  describe "Rack::Test::UploadedFile object" do
    before { model.asv_errorable.attach(attachable) }

    let(:attachable) { Rack::Test::UploadedFile.new(source_path, file_not_matching_requirements[:content_type]) }
    let(:expected_filename) { path_filename }

    it { is_expected_not_to_be_valid(context: :create) }
    it { is_expected_to_have_error_options(error_options, context: :create) }
  end

  describe "ActiveStorage::Blob object" do
    before { model.asv_errorable.attach(attachable) }

    let(:attachable) { create_blob_from_file(file_not_matching_requirements) }
    let(:expected_filename) { declared_filename }

    it { is_expected_not_to_be_valid(context: :create) }
    it { is_expected_to_have_error_options(error_options, context: :create) }
  end

  describe "String object representing the signed reference to blob" do
    before { model.asv_errorable.attach(attachable) }

    let(:attachable) { create_blob_from_file(file_not_matching_requirements).signed_id }
    let(:expected_filename) { declared_filename }

    it { is_expected_not_to_be_valid(context: :create) }
    it { is_expected_to_have_error_options(error_options, context: :create) }
  end

  describe "File object" do
    let(:attachable) { File.open(source_path) }
    let(:expected_filename) { path_filename }

    if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
      before { model.asv_errorable.attach(attachable) }

      it { is_expected_not_to_be_valid(context: :create) }
      it { is_expected_to_have_error_options(error_options, context: :create) }
    else
      it "raises Rails' attachable error" do
        expect { model.asv_errorable.attach(attachable) }.to raise_error(ArgumentError, /Could not find or build blob/)
      end
    end
  end

  describe "Pathname object" do
    let(:attachable) { Pathname.new(source_path) }
    let(:expected_filename) { path_filename }

    if Rails.gem_version >= Gem::Version.new("7.1.0.rc1")
      before { model.asv_errorable.attach(attachable) }

      it { is_expected_not_to_be_valid(context: :create) }
      it { is_expected_to_have_error_options(error_options, context: :create) }
    else
      it "raises Rails' attachable error" do
        expect { model.asv_errorable.attach(attachable) }.to raise_error(ArgumentError, /Could not find or build blob/)
      end
    end
  end

  def uploaded_file_from(hash)
    tempfile = Tempfile.new
    tempfile.binmode
    IO.copy_stream(hash[:io], tempfile)
    hash[:io].rewind
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: hash[:filename],
      type: hash[:content_type]
    )
  end
end
