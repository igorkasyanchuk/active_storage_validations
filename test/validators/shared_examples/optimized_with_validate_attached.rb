module OptimizedWithValidateAttached
  extend ActiveSupport::Concern
  METADATA_VALIDATOR_CLASS_NAMES = [
    "ActiveStorageValidations::AspectRatioValidator",
    "ActiveStorageValidations::ContentTypeValidator",
    "ActiveStorageValidations::DimensionValidator",
    "ActiveStorageValidations::DurationValidator",
    "ActiveStorageValidations::PagesValidator",
    "ActiveStorageValidations::ProcessableFileValidator"
  ].freeze

  class_methods do
    def metadata_validator_context?
      METADATA_VALIDATOR_CLASS_NAMES.any? { |class_name| name.start_with?(class_name) }
    end
  end

  included do
    subject { validator_test_class::OptimizedWithValidateAttached.new(params) }

    if metadata_validator_context?
      describe "Metadata related behavior" do
        let(:metadata_analyzer_to_be_called) do
          case validator_sym
          when :aspect_ratio then ActiveStorageValidations::Analyzer::ImageAnalyzer
          when :content_type then ActiveStorageValidations::Analyzer::ContentTypeAnalyzer
          when :dimension then ActiveStorageValidations::Analyzer::ImageAnalyzer
          when :duration then ActiveStorageValidations::Analyzer::AudioAnalyzer
          when :processable_file then ActiveStorageValidations::Analyzer::ImageAnalyzer # because of tested file
          when :pages then ActiveStorageValidations::Analyzer::PdfAnalyzer
          end
        end

        describe "#validate_attached" do
          let(:file_not_matching_requirements) { file_data_not_matching_requirements[:file] }

          describe "size validation" do
            let(:file_data_not_matching_requirements) do
              case validator_sym
              when :aspect_ratio then { file: image_150x150_28ko, file_size_string: "27 KB" }
              when :content_type then { file: image_150x150_28ko, file_size_string: "27 KB" }
              when :dimension then { file: image_150x150_28ko, file_size_string: "27 KB" }
              when :duration then { file: audio_65_7ko, file_size_string: "65.7 KB" }
              when :processable_file then { file: image_150x150_28ko, file_size_string: "27 KB" }
              when :pages then { file: pdf_22ko_file, file_size_string: "22 KB" }
              end
            end
            let(:file_matching_requirements) do
              case validator_sym
              when :aspect_ratio then image_150x150_file_0_3ko
              when :content_type then image_150x150_file_0_3ko
              when :dimension then image_150x150_file_0_3ko
              when :duration then audio_4ko
              when :processable_file then image_150x150_file_0_3ko
              when :pages then pdf_2ko_file
              end
            end
            let(:error_options) do
              {
                filename: file_not_matching_requirements[:filename],
                file_size: file_data_not_matching_requirements[:file_size_string],
                min: nil,
                max: "10 KB"
              }
            end

            %i[one many].each do |relationship_type|
              describe "when passed a file not matching size validation requirements for has_#{relationship_type}_attached" do
                let(:attribute) do
                  relationship_type == :one ? :short_circuit_metadata_analysis_because_of_size_validaton : :short_circuit_metadata_many_analysis_because_of_size_validaton
                end

                before do
                  attachables = relationship_type == :one ? file_not_matching_requirements : [ file_not_matching_requirements ]
                  subject.public_send(attribute).attach(attachables)
                end

                it "does not call the media analyzer for metadata validators" do
                  assert_called_on_instance_of(metadata_analyzer_to_be_called, :metadata, times: 0, returns: {}) do
                    subject.valid?
                  end
                end

                it "loggs as `asv.heavyweight_validations_skipped` event with data" do
                  assert_logged({
                    event: "asv.heavyweight_validations_skipped",
                    model: subject.class.name,
                    attribute: attribute,
                    skipped_heavyweight_validators: [ validator_sym ]
                  }) do
                    subject.validate
                  end
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("file_size_not_less_than", error_options: error_options, validator: :size) }
                it { is_expected_to_have_error_options(error_options, validator: :size) }
              end
            end
          end

          describe "total_size validation" do
            let(:files) { [ image_150x150_28ko, image_150x150_28ko, image_150x150_28ko ] }
            let(:error_options) do
              {
                total_file_size: "81.1 KB",
                min: nil,
                max: "10 KB"
              }
            end

            describe "when passed a total size of files not matching total size validation requirements for has_many_attached" do
              let(:attribute) do
                :short_circuit_metadata_many_analysis_because_of_total_size_validaton
              end

              before do
                subject.public_send(attribute).attach(files)
              end

              it "does not call the media analyzer for metadata validators" do
                assert_called_on_instance_of(metadata_analyzer_to_be_called, :metadata, times: 0, returns: {}) do
                  subject.valid?
                end
              end

              it "loggs as `asv.heavyweight_validations_skipped` event with data" do
                assert_logged({
                  event: "asv.heavyweight_validations_skipped",
                  model: subject.class.name,
                  attribute: attribute,
                  skipped_heavyweight_validators: [ validator_sym ]
                }) do
                  subject.validate
                end
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("total_file_size_not_less_than", error_options: error_options, validator: :total_size) }
              it { is_expected_to_have_error_options(error_options, validator: :total_size) }
            end
          end

          describe "content_type validation" do
            let(:file_data_not_matching_requirements) do
              case validator_sym
              when :aspect_ratio then { file: pdf_22ko_file, authorized_human_content_types: "PNG" }
              when :content_type then { file: pdf_22ko_file, authorized_human_content_types: "PNG" }
              when :dimension then { file: pdf_22ko_file, authorized_human_content_types: "PNG" }
              when :duration then { file: pdf_22ko_file, authorized_human_content_types: "MPGA" }
              when :processable_file then { file: pdf_22ko_file, authorized_human_content_types: "PNG" }
              when :pages then { file: audio_65_7ko, authorized_human_content_types: "PDF" }
              end
            end
            let(:error_options) do
              {
                filename: file_not_matching_requirements[:filename],
                authorized_human_content_types: file_data_not_matching_requirements[:authorized_human_content_types],
                count: 1
              }
            end

            %i[one many].each do |relationship_type|
              describe "when passed a file not matching content type validation requirements for has_#{relationship_type}_attached" do
                let(:attribute) do
                  relationship_type == :one ? :short_circuit_metadata_analysis_because_of_content_type_validaton : :short_circuit_metadata_many_analysis_because_of_content_type_validaton
                end

                before do
                  attachables = relationship_type == :one ? file_not_matching_requirements : [ file_not_matching_requirements ]
                  subject.public_send(attribute).attach(attachables)
                end

                it "does not call the media analyzer for metadata validators" do
                  assert_called_on_instance_of(metadata_analyzer_to_be_called, :metadata, times: 0, returns: {}) do
                    subject.valid?
                  end
                end

                it "loggs as `asv.heavyweight_validations_skipped` event with data" do
                  assert_logged({
                    event: "asv.heavyweight_validations_skipped",
                    model: subject.class.name,
                    attribute: attribute,
                    skipped_heavyweight_validators: [ validator_sym ]
                  }) do
                    subject.validate
                  end
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("content_type_invalid", error_options: error_options, validator: :content_type) }
                it { is_expected_to_have_error_options(error_options, validator: :content_type) }
              end
            end
          end

          describe "limit validation" do
            let(:files) { [ image_150x150_28ko, image_150x150_28ko, image_150x150_28ko ] }
            let(:error_options) do
              {
                min: 1,
                max: 2,
                count: 3
              }
            end

            describe "when passed a count of files not matching limit validation requirements for has_many_attached" do
              let(:attribute) do
                :short_circuit_metadata_many_analysis_because_of_limit_validaton
              end

              before do
                subject.public_send(attribute).attach(files)
              end

              it "does not call the media analyzer for metadata validators" do
                assert_called_on_instance_of(metadata_analyzer_to_be_called, :metadata, times: 0, returns: {}) do
                  subject.valid?
                end
              end

              it "loggs as `asv.heavyweight_validations_skipped` event with data" do
                assert_logged({
                  event: "asv.heavyweight_validations_skipped",
                  model: subject.class.name,
                  attribute: attribute,
                  skipped_heavyweight_validators: [ validator_sym ]
                }) do
                  subject.validate
                end
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("limit_out_of_range", error_options: error_options, validator: :limit) }
              it { is_expected_to_have_error_options(error_options, validator: :limit) }
            end
          end
        end
      end
    end
  end
end
