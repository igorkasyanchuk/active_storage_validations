# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::DurationValidator do
  let(:validator_test_class) { Duration::Validator }
  let(:params) { {} }

  # Expected duration value for the I18n.locale active when the expectation runs
  # (error messages are checked in every bundled locale).
  def seconds_in_words(seconds)
    localized do
      connectors = I18n.t("active_storage_validations.duration.connectors")
      ActiveSupport::Duration.build(seconds).parts
        .map { |unit, count| I18n.t("active_storage_validations.duration.#{unit}", count: count) }
        .to_sentence(locale: false, **connectors)
    end
  end

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "#check_validity!" do
    it_behaves_like "checks validator validity"
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"


    describe ":less_than" do
      let(:file_having_lower_than_less_than_option) { audio_1s }
      let(:file_having_exact_less_than_option) { audio_2s }
      let(:file_having_higher_than_less_than_option) { audio_5s }
      let(:error_name) { "duration_not_less_than" }
      let(:error_options_for_file_having_exact_less_than_option) do
        {
          duration: seconds_in_words(2),
          filename: file_having_exact_less_than_option[:filename],
          min: nil,
          max: seconds_in_words(2)
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_option) do
        {
          duration: seconds_in_words(5),
          filename: file_having_higher_than_less_than_option[:filename],
          min: nil,
          max: seconds_in_words(2)
        }
      end

      it_behaves_like "comparison less_than option"
    end

    describe ":less_than_or_equal_to" do
      let(:file_having_lower_than_less_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_less_than_or_equal_to_option) { audio_2s }
      let(:file_having_higher_than_less_than_or_equal_to_option) { audio_5s }
      let(:error_name) { "duration_not_less_than_or_equal_to" }
      let(:error_options_for_file_having_exact_less_than_or_equal_to_option) do
        {
          duration: seconds_in_words(2),
          filename: file_having_exact_less_than_or_equal_to_option[:filename],
          min: nil,
          max: seconds_in_words(2)
        }
      end
      let(:error_options_for_file_having_higher_than_less_than_or_equal_to_option) do
        {
          duration: seconds_in_words(5),
          filename: file_having_higher_than_less_than_or_equal_to_option[:filename],
          min: nil,
          max: seconds_in_words(2)
        }
      end

      it_behaves_like "comparison less_than_or_equal_to option"
    end

    describe ":greater_than" do
      let(:file_having_lower_than_greater_than_option) { audio_1s }
      let(:file_having_exact_greater_than_option) { audio_7s }
      let(:file_having_higher_than_greater_than_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than" }
      let(:error_options_for_file_having_lower_than_greater_than_option) do
        {
          duration: seconds_in_words(1),
          filename: file_having_lower_than_greater_than_option[:filename],
          min: seconds_in_words(7),
          max: nil
        }
      end
      let(:error_options_for_file_having_exact_greater_than_option) do
        {
          duration: seconds_in_words(7),
          filename: file_having_exact_greater_than_option[:filename],
          min: seconds_in_words(7),
          max: nil
        }
      end

      it_behaves_like "comparison greater_than option"
    end

    describe ":greater_than_or_equal_to" do
      let(:file_having_lower_than_greater_than_or_equal_to_option) { audio_1s }
      let(:file_having_exact_greater_than_or_equal_to_option) { audio_7s }
      let(:file_having_higher_than_greater_than_or_equal_to_option) { audio_10s }
      let(:error_name) { "duration_not_greater_than_or_equal_to" }
      let(:error_options_for_file_having_lower_than_greater_than_or_equal_to_option) do
        {
          duration: seconds_in_words(1),
          filename: file_having_lower_than_greater_than_or_equal_to_option[:filename],
          min: seconds_in_words(7),
          max: nil
        }
      end

      it_behaves_like "comparison greater_than_or_equal_to option"
    end

    describe ":between" do
      let(:file_having_lower_than_lower_bound_between_option) { audio_1s }
      let(:file_having_exact_lower_bound_between_option) { audio_2s }
      let(:file_having_between_bounds_between_option) { audio_5s }
      let(:file_having_exact_higher_bound_between_option) { audio_7s }
      let(:file_having_higher_than_higher_bound_between_option) { audio_10s }
      let(:error_name) { "duration_not_between" }
      let(:error_options_for_file_having_lower_than_lower_bound_between_option) do
        {
          duration: seconds_in_words(1),
          filename: file_having_lower_than_lower_bound_between_option[:filename],
          min: seconds_in_words(2),
          max: seconds_in_words(7)
        }
      end
      let(:error_options_for_file_having_higher_than_higher_bound_between_option) do
        {
          duration: seconds_in_words(10),
          filename: file_having_higher_than_higher_bound_between_option[:filename],
          min: seconds_in_words(2),
          max: seconds_in_words(7)
        }
      end

      it_behaves_like "comparison between option"
    end

    describe "exclusive :between (e.g. between: 2.seconds...7.seconds)" do
      let(:attribute) { :between_exclusive }
      let(:error_options) do
        {
          duration: seconds_in_words(7),
          filename: audio_7s[:filename],
          min: seconds_in_words(2),
          max: seconds_in_words(6)
        }
      end

      context "when provided with a file inside the exclusive range" do
        subject(:record) { model.public_send(attribute).attach(audio_5s) and model }

        it { is_expected_to_be_valid }
      end

      context "when provided with a file at the exclusive end bound" do
        subject(:record) { model.public_send(attribute).attach(audio_7s) and model }

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("duration_not_between", with_locales: [ "en" ], error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end
    end

    describe ":equal_to" do
      let(:file_having_lower_than_equal_to_option) { audio_2s }
      let(:file_having_exact_equal_to_option) { audio_5s }
      let(:file_having_higher_than_equal_to_option) { audio_7s }
      let(:error_name) { "duration_not_equal_to" }
      let(:error_options_for_file_having_lower_than_equal_to_option) do
        {
          duration: seconds_in_words(2),
          filename: file_having_lower_than_equal_to_option[:filename],
          exact: seconds_in_words(5)
        }
      end
      let(:error_options_for_file_having_higher_than_equal_to_option) do
        {
          duration: seconds_in_words(7),
          filename: file_having_higher_than_equal_to_option[:filename],
          exact: seconds_in_words(5)
        }
      end

      it_behaves_like "comparison equal_to option"
    end

    describe "Edge cases" do
      context "when the passed file is not a valid media" do
        subject(:record) { model.public_send(attribute).attach(empty_io_file) and model }

        let(:attribute) { :with_invalid_media_file }
        let(:error_options) do
          {
            filename: empty_io_file[:filename]
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      context "when the passed file lasts less than a second" do
        # validates :less_than, duration: { less_than: 2.seconds }
        subject(:record) { model.less_than.attach(audio_0_5s) and model }

        it { is_expected_to_be_valid }
      end

      context "when a file lasting less than a second breaks the constraint" do
        # validates :greater_than, duration: { greater_than: 7.seconds }
        subject(:record) { model.greater_than.attach(audio_0_5s) and model }

        it { is_expected_not_to_be_valid }

        it "reports a duration error rather than unreadable metadata" do
          record.valid?

          expect(record.errors.map(&:type)).to eq([ :duration_not_greater_than ])
        end
      end

      context "when the audio container carries the duration but the stream does not (WebM / Opus)" do
        # validates :less_than, duration: { less_than: 2.seconds }
        subject(:record) { model.less_than.attach(audio_3s_webm) and model }

        let(:error_options) do
          {
            duration: seconds_in_words(3),
            filename: audio_3s_webm[:filename],
            min: nil,
            max: seconds_in_words(2)
          }
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("duration_not_less_than", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

      describe "when the attached file is missing from storage" do
        let(:attribute) { :less_than }
        let(:file_for_attachment_missing) { audio_1s }

        it_behaves_like "reports attachment_missing"
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "audio.mp3")),
        filename: "audio.mp3",
        content_type: "audio/mp3"
      }
    end

    it_behaves_like "is performance optimized"

    context "when the analyzer cannot extract the requested metadata" do
      subject(:model) { Duration::Validator::IsPerformanceOptimized.new }

      before { model.is_performance_optimized.attach(pdf_150x150_file) }

      it "memoizes the unavailable duration on the blob" do
        model.valid?

        expect(model.is_performance_optimized.blob.active_storage_validations_metadata).to include(duration: "")
      end

      it "does not analyze the file again on the next validation" do
        analyzer = instance_double(ActiveStorageValidations::Analyzer::PdfAnalyzer)
        allow(ActiveStorageValidations::Analyzer::PdfAnalyzer).to receive(:new).and_return(analyzer)
        allow(analyzer).to receive(:metadata).and_return({ width: 150, height: 150, pages: 1 })

        2.times { model.valid? }

        expect(analyzer).to have_received(:metadata).once
      end
    end
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end

  describe "duration values in error messages" do
    subject(:duration_in_words) { validator.send(:format_bound_value, seconds) }

    let(:validator) { described_class.new(attributes: :file, less_than: 1.minute) }

    {
      en: { 1 => "1 second", 2.5 => "2.5 seconds", 90 => "1 minute and 30 seconds", 3661 => "1 hour, 1 minute, and 1 second" },
      fr: { 1 => "1 seconde", 90 => "1 minute et 30 secondes", 3661 => "1 heure, 1 minute et 1 seconde" },
      de: { 90 => "1 Minute und 30 Sekunden" },
      ja: { 90 => "1分30秒", 3661 => "1時間1分1秒" },
      pl: { 1 => "1 sekunda", 5 => "5 sekund" }
    }.each do |locale, expectations|
      context "with the #{locale} locale" do
        around { |example| I18n.with_locale(locale) { example.run } }

        expectations.each do |value, expected|
          context "with #{value} seconds" do
            let(:seconds) { value }

            it { is_expected.to eq(expected) }
          end
        end
      end
    end

    context "with a locale the gem does not ship" do
      around do |example|
        enforce_available_locales = I18n.enforce_available_locales
        I18n.enforce_available_locales = false
        I18n.with_locale(:pt) { example.run }
      ensure
        I18n.enforce_available_locales = enforce_available_locales
      end

      let(:seconds) { 90 }

      it "falls back to the English wording" do
        expect(duration_in_words).to eq("1 minute and 30 seconds")
      end
    end

    context "with a zero duration" do
      let(:seconds) { 0 }

      it "renders seconds like ActiveSupport::Duration#inspect" do
        expect(duration_in_words).to eq("0 seconds")
      end
    end
  end
end
