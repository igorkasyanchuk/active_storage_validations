# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageValidations::DimensionValidator do
  let(:validator_test_class) { Dimension::Validator }
  let(:params) { {} }

  describe "ASVAttachable shared behavior" do
    it_behaves_like "ASVAttachable"
  end

  describe "#initialize_error_options" do
    it_behaves_like "ASVErrorable"
  end

  describe "#check_validity!" do
    it_behaves_like "checks validator validity"

    describe "#ensure_dimension_option_validity" do
      subject(:validator) { described_class.new(attributes: [ :file ], **validator_options) }

      %i[width height].each do |dimension|
        describe ":#{dimension}" do
          context "when the value is an Integer, a Proc or a valid Hash" do
            [ 150, ->(_record) { 150 }, { min: 100 }, { max: 0 }, { min: 100, max: ->(_record) { 200 } }, { in: 100..200 } ].each do |value|
              context "with #{value.inspect}" do
                let(:validator_options) { { dimension => value } }

                it { expect { validator }.not_to raise_error }
              end
            end
          end

          context "when the value is a Range (e.g. #{dimension}: 100..200)" do
            let(:validator_options) { { dimension => 100..200 } }
            let(:error_message) do
              "{ #{dimension}: value } value must be an Integer, a Proc or a Hash with :min, :max or :in (e.g. #{dimension}: { in: 100..200 })"
            end

            it { expect { validator }.to raise_error(ArgumentError, error_message) }
          end

          context "when the value is nil" do
            let(:validator_options) { { dimension => nil } }

            it { expect { validator }.to raise_error(ArgumentError, /\{ #{dimension}: value \} value must be an Integer/) }
          end

          [ {}, { minimum: 1000 }, { min: 100, maximum: 200 } ].each do |value|
            context "when the Hash has no known key (e.g. #{dimension}: #{value.inspect})" do
              let(:validator_options) { { dimension => value } }
              let(:error_message) { "{ #{dimension}: { … } } only accepts :min, :max and :in (got #{value.keys.inspect})" }

              it { expect { validator }.to raise_error(ArgumentError, error_message) }
            end
          end

          context "when :in is combined with :min / :max" do
            let(:validator_options) { { dimension => { in: 100..200, max: 300 } } }
            let(:error_message) { "{ #{dimension}: { in: } } cannot be combined with :min / :max" }

            it { expect { validator }.to raise_error(ArgumentError, error_message) }
          end

          %i[min max].each do |bound|
            context "when :#{bound} is a Range (e.g. #{dimension}: { #{bound}: 100..200 })" do
              let(:validator_options) { { dimension => { bound => 100..200 } } }
              let(:error_message) { "{ #{dimension}: { #{bound}: value } } value must be an Integer or a Proc" }

              it { expect { validator }.to raise_error(ArgumentError, error_message) }
            end
          end
        end
      end
    end

    describe "#ensure_min_max_not_combined_with_dimension" do
      subject(:validator) { described_class.new(attributes: [ :file ], **validator_options) }

      let(:error_message) do
        "{ min: } / { max: } cannot be combined with :width / :height (use width: { min:, max: } and height: { min:, max: } instead)"
      end

      context "when :min is combined with an Integer :width" do
        let(:validator_options) { { min: 100..100, width: 150 } }

        it { expect { validator }.to raise_error(ArgumentError, error_message) }
      end

      context "when :max is combined with a :height Hash" do
        let(:validator_options) { { max: 800..600, height: { min: 100 } } }

        it { expect { validator }.to raise_error(ArgumentError, error_message) }
      end

      context "when :min and :max are used alone" do
        let(:validator_options) { { min: 100..100, max: 800..600 } }

        it { expect { validator }.not_to raise_error }
      end
    end

    describe "#ensure_dimension_in_option_validity" do
      context "when the passed option is a Range" do
        subject(:model) { validator_test_class::CheckValidityDimensionInRange.new(params) }

        it "does not perform a check, and therefore is valid" do
          expect { model }.not_to raise_error
        end
      end

      context "when the passed option is a Proc" do
        subject(:model) { validator_test_class::CheckValidityDimensionInProc.new(params) }

        it "does not perform a check, and therefore is valid" do
          expect { model }.not_to raise_error
        end
      end

      context "when the passed option is neither a Range nor a Proc" do
        subject(:model) { validator_test_class::CheckValidityInvalidDimensionIn.new(params) }

        let(:error_message) { "{ width: { in: value } } value must be a Range (min..max)" }

        it "raises an error at model initialization" do
          expect { model }.to raise_error(ArgumentError, error_message)
        end
      end

      context "when the range is missing a bound" do
        subject(:validator) { described_class.new(attributes: [ :file ], width: { in: range }) }

        let(:bounded_range_error_message) do
          "{ width: { in: } } value must be a Range with both bounds (use width: { min: } or width: { max: } for a single bound)"
        end

        context "when the range is endless (e.g. width: { in: 100.. })" do
          let(:range) { 100.. }

          it "raises an error at validator initialization" do
            expect { validator }.to raise_error(ArgumentError, bounded_range_error_message)
          end
        end

        context "when the range is beginless (e.g. width: { in: ..800 })" do
          let(:range) { ..800 }

          it "raises an error at validator initialization" do
            expect { validator }.to raise_error(ArgumentError, bounded_range_error_message)
          end
        end

        context "when the range is returned by a Proc" do
          let(:range) { ->(_record) { 100.. } }

          it "cannot be checked at validator initialization" do
            expect { validator }.not_to raise_error
          end

          it "still resolves the error bounds without raising" do
            flat_options = validator.send(:process_options, nil)

            expect(flat_options[:width][:min]).to eq(100)
            expect(flat_options[:width][:max]).to be_nil
          end
        end
      end

      context "when a Proc returns a frozen Hash" do
        subject(:validator) { described_class.new(attributes: [ :file ], width: ->(_record) { limits }) }

        let(:limits) { { in: 100..140 }.freeze }

        it "resolves the bounds without modifying the Hash" do
          flat_options = validator.send(:process_options, nil)

          expect(flat_options[:width]).to include(min: 100, max: 140)
          expect(limits).to eq({ in: 100..140 })
        end
      end
    end

    describe "#ensure_min_max_option_validity" do
      %i[min max].each do |bound|
        context "when the passed option is a Range" do
          subject(:model) { "#{validator_test_class}::CheckValidity#{bound.to_s.capitalize}Range".constantize.new(params) }

          it "does not perform a check, and therefore is valid" do
            expect { model }.not_to raise_error
          end
        end

        context "when the passed option is a Proc" do
          subject(:model) { "#{validator_test_class}::CheckValidity#{bound.to_s.capitalize}Proc".constantize.new(params) }

          it "does not perform a check, and therefore is valid" do
            expect { model }.not_to raise_error
          end
        end

        context "when the passed option is neither a Range nor a Proc" do
          subject(:model) { "#{validator_test_class}::CheckValidityInvalid#{bound.to_s.capitalize}".constantize.new(params) }

          let(:error_message) { "{ #{bound}: value } value must be a Range (#{bound}_width..#{bound}_height)" }

          it "raises an error at model initialization" do
            expect { model }.to raise_error(ArgumentError, error_message)
          end
        end

        context "when the range is missing a bound" do
          subject(:validator) { described_class.new(attributes: [ :file ], bound => range) }

          let(:bounded_range_error_message) do
            "{ #{bound}: } value must be a Range with both bounds (#{bound}_width..#{bound}_height)"
          end

          context "when the range is endless" do
            let(:range) { 100.. }

            it "raises an error at validator initialization" do
              expect { validator }.to raise_error(ArgumentError, bounded_range_error_message)
            end
          end

          context "when the range is returned by a Proc" do
            let(:range) { ->(_record) { 100.. } }

            it "cannot be checked at validator initialization" do
              expect { validator }.not_to raise_error
            end
          end
        end
      end
    end
  end

  describe "Validator checks" do
    let(:model) { validator_test_class::Check.new(params) }

    it_behaves_like "works fine with attachables"


    %w[width height].each do |dimension|
      describe ":#{dimension} option" do
        %w[value proc].each do |value_type|
          describe value_type do
            describe ":#{dimension} (e.g { #{dimension}: 500 })" do
              # validates :width, dimension: { width: 500 }
              # validates :width_proc, dimension: { width: -> (record) { 500 } }
              # validates :height, dimension: { height: 500 }
              # validates :height_proc, dimension: { height: -> (record) { 500 } }
              let(:attribute) { :"#{dimension}#{'_proc' if value_type == 'proc'}" }

              context "when provided with a lower #{dimension} than the #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              context "when provided with the same #{dimension} value as specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    filename: "image_600x800_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :min (e.g { #{dimension}: { min: 500 } })" do
              # validates :width_min, dimension: { width: { min: 500 } }
              # validates :width_min_proc, dimension: { width: { min: -> (record) { 500 } } }
              # validates :height_min, dimension: { height: { min: 500 } }
              # validates :height_min_proc, dimension: { height: { min: -> (record) { 500 } } }
              let(:attribute) { :"#{dimension}_min#{'_proc' if value_type == 'proc'}" }

              context "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_greater_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              context "when provided with the same #{dimension} value as specified as min in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

                it { is_expected_to_be_valid }
              end
            end

            describe "#{dimension}: :max (e.g { #{dimension}: { max: 500 } })" do
              # validates :width_max, dimension: { width: { max: 500 } }
              # validates :width_max_proc, dimension: { width: { max: -> (record) { 500 } } }
              # validates :height_max, dimension: { height: { max: 500 } }
              # validates :height_max_proc, dimension: { height: { max: -> (record) { 500 } } }
              let(:attribute) { :"#{dimension}_max#{'_proc' if value_type == 'proc'}" }

              context "when provided with a lower #{dimension} than the max #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with the same #{dimension} value as specified as max in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with a higher #{dimension} than the #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

                let(:error_options) do
                  {
                    length: 500,
                    filename: "image_600x800_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_less_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :min and :max (e.g { #{dimension}: { min: 400, max: 600 } })" do
              # validates :width_min_max, dimension: { width: { min: 400, max: 600 } }
              # validates :width_min_max_proc, dimension: { width: { min: -> (record) { 400 }, max: -> (record) { 600 } } }
              # validates :height_min_max, dimension: { height: { min: 400, max: 600 } }
              # validates :height_min_max_proc, dimension: { height: { min: -> (record) { 400 }, max: -> (record) { 600 } } }
              let(:attribute) { :"#{dimension}_min_max#{'_proc' if value_type == 'proc'}" }

              context "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    length: 400,
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_greater_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              context "when provided with a #{dimension} value as included in the min and max #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with a higher #{dimension} than the max #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_1200x900_file) and model }

                let(:error_options) do
                  {
                    length: 600,
                    filename: "image_1200x900_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_less_than_or_equal_to", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            describe "#{dimension}: :in (e.g { #{dimension}: { in: 400..600 } })" do
              # validates :width_in, dimension: { width: { in: 400..600 } }
              # validates :width_in_proc, dimension: { width: { in: -> (record) { 400..600 } } }
              # validates :height_in, dimension: { height: { in: 400..600 } }
              # validates :height_in_proc, dimension: { height: { in: -> (record) { 400..600 } } }
              let(:attribute) { :"#{dimension}_in#{'_proc' if value_type == 'proc'}" }

              context "when provided with a lower #{dimension} than the min #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

                let(:error_options) do
                  {
                    min: 400,
                    max: 600,
                    filename: "image_150x150_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_included_in", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end

              context "when provided with a #{dimension} value as included in the min and max #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                it { is_expected_to_be_valid }
              end

              context "when provided with a higher #{dimension} than the max #{dimension} specified in the model validations" do
                subject(:record) { model.public_send(attribute).attach(image_1200x900_file) and model }

                let(:error_options) do
                  {
                    min: 400,
                    max: 600,
                    filename: "image_1200x900_file.png"
                  }
                end

                it { is_expected_not_to_be_valid }
                it { is_expected_to_include_error_message("dimension_#{dimension}_not_included_in", error_options: error_options) }
                it { is_expected_to_have_error_options(error_options) }
              end
            end

            if value_type == "value"
              describe "#{dimension}: exclusive :in (e.g { #{dimension}: { in: 400...600 } })" do
                # validates :width_in_exclusive, dimension: { width: { in: 400...600 } }
                # validates :height_in_exclusive, dimension: { height: { in: 400...600 } }
                let(:attribute) { :"#{dimension}_in_exclusive" }

                context "when provided with a #{dimension} value inside the exclusive range" do
                  subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

                  it { is_expected_to_be_valid }
                end

                context "when provided with the exclusive end bound (#{dimension} = 600)" do
                  subject(:record) { model.public_send(attribute).attach(image_600x600_file) and model }

                  let(:error_options) do
                    {
                      min: 400,
                      max: 599,
                      filename: "image_600x600_file.png"
                    }
                  end

                  it { is_expected_not_to_be_valid }
                  it { is_expected_to_include_error_message("dimension_#{dimension}_not_included_in", error_options: error_options) }
                  it { is_expected_to_have_error_options(error_options) }
                end
              end
            end
          end
        end
      end
    end

    describe ":min option" do
      %w[value proc].each do |value_type|
        describe value_type do
          describe ":min (e.g { min: 500..500 })" do
            # validates :min, dimension: { min: 500..500   }
            # validates :min_proc, dimension: { min: -> (record) { 500..500 } }
            let(:attribute) { :"min#{'_proc' if value_type == 'proc'}" }

            context "when provided with a lower width or height than the min specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

              let(:error_options) do
                {
                  width: 500,
                  height: 500,
                  filename: "image_150x150_file.png"
                }
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("dimension_min_not_included_in", error_options: error_options) }
              it { is_expected_to_have_error_options(error_options) }
            end

            context "when provided with the same width or height value as specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

              it { is_expected_to_be_valid }
            end

            context "when provided with a higher width or height than the min specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

              it { is_expected_to_be_valid }
            end
          end
        end
      end
    end

    describe ":max option" do
      %w[value proc].each do |value_type|
        describe value_type do
          describe ":max (e.g { max: 500..500 })" do
            # validates :max, dimension: { max: 500..500   }
            # validates :max_proc, dimension: { max: -> (record) { 500..500 } }
            let(:attribute) { :"max#{'_proc' if value_type == 'proc'}" }

            context "when provided with a lower width or height than the max specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

              it { is_expected_to_be_valid }
            end

            context "when provided with the same width or height value as specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

              it { is_expected_to_be_valid }
            end

            context "when provided with a higher width or height than the max specified in the model validations" do
              subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

              let(:error_options) do
                {
                  width: 500,
                  height: 500,
                  filename: "image_600x800_file.png"
                }
              end

              it { is_expected_not_to_be_valid }
              it { is_expected_to_include_error_message("dimension_max_not_included_in", error_options: error_options) }
              it { is_expected_to_have_error_options(error_options) }
            end
          end
        end
      end
    end

    describe ":min and :max options together" do
      # validates :min_max, dimension: { min: 400..500, max: 600..700 }
      # validates :min_max_proc, dimension: { min: -> (record) { 400..500 }, max: -> (record) { 600..700 } }
      # restricts width to 400..600 and height to 500..700
      %w[value proc].each do |value_type|
        describe value_type do
          let(:attribute) { :"min_max#{'_proc' if value_type == 'proc'}" }

          context "when provided with an image within both width and height bounds" do
            subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

            it { is_expected_to_be_valid }
          end

          context "when provided with an image below the min width or height" do
            subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

            let(:error_options) do
              {
                width: 400,
                height: 500,
                filename: "image_150x150_file.png"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("dimension_min_not_included_in", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end

          context "when provided with an image above the max width or height" do
            subject(:record) { model.public_send(attribute).attach(image_800x600_file) and model }

            let(:error_options) do
              {
                width: 600,
                height: 700,
                filename: "image_800x600_file.png"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("dimension_max_not_included_in", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end
    end

    describe "Integration tests" do
      describe ":width exact + :height exact" do
        let(:attribute) { :width_height_exact }

        context "when provided with an image that has the same width and height as specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_600x600_file) and model }

          it { is_expected_to_be_valid }
        end

        context "when provided with an image that has a different width than specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_800x600_file) and model }

          let(:error_options) do
            {
              length: 600,
              filename: "image_800x600_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        context "when provided with an image that has a different height than specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_600x800_file) and model }

          let(:error_options) do
            {
              length: 600,
              filename: "image_600x800_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        context "when provided with an image that has a different height and a different width than specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_1200x900_file) and model }

          let(:error_options) do
            {
              length: 600,
              filename: "image_1200x900_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end

      describe ":width in + :height in" do
        let(:attribute) { :width_height_in }

        context "when provided with an image that has a valid width and height as specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_600x600_file) and model }

          it { is_expected_to_be_valid }
        end

        context "when provided with an image that has lower width than the min specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_500x700_file) and model }

          let(:error_options) do
            {
              min: 550,
              max: 750,
              filename: "image_500x700_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        context "when provided with an image that has lower height than the min specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_700x500_file) and model }

          let(:error_options) do
            {
              min: 550,
              max: 750,
              filename: "image_700x500_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_height_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end

        context "when provided with an image that has lower width and height than the mins specified in the model validations" do
          subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

          let(:error_options) do
            {
              min: 550,
              max: 750,
              filename: "image_500x500_file.png"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_included_in", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_included_in", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end

    describe "Edge cases" do
      describe "width: { max: 0 }" do
        %w[value proc].each do |value_type|
          describe value_type do
            subject(:record) { model.public_send(attribute).attach(image_150x150_file) and model }

            let(:attribute) { :"width_max_zero#{'_proc' if value_type == 'proc'}" }
            let(:error_options) do
              {
                length: 0,
                filename: "image_150x150_file.png"
              }
            end

            it { is_expected_not_to_be_valid }
            it { is_expected_to_include_error_message("dimension_width_not_less_than_or_equal_to", error_options: error_options) }
            it { is_expected_to_have_error_options(error_options) }
          end
        end
      end

      context "when ActiveStorage.variant_processor is :disabled" do
        subject(:record) { model.public_send(attribute).attach(image_500x500_file) and model }

        let(:attribute) { :width }
        let(:error_options) do
          {
            filename: "image_500x500_file.png"
          }
        end

        around do |example|
          previous = ActiveStorage.variant_processor
          ActiveStorage.variant_processor = :disabled
          example.run
        ensure
          ActiveStorage.variant_processor = previous
        end

        it "fails closed with media_metadata_missing instead of raising" do
          expect { record.valid? }.not_to raise_error
        end

        it { is_expected_not_to_be_valid }
        it { is_expected_to_include_error_message("media_metadata_missing", error_options: error_options) }
        it { is_expected_to_have_error_options(error_options) }
      end

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

      describe "when the attached file is missing from storage" do
        let(:attribute) { :width }
        let(:file_for_attachment_missing) { image_150x150_file }

        it_behaves_like "reports attachment_missing"
      end

      context "when the passed file is a pdf" do
        describe "valid pdf" do
          subject(:record) { model.public_send(attribute).attach(pdf_150x150_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              filename: pdf_150x150_file[:filename]
            }
          end

          it { is_expected_to_be_valid }
        end

        describe "invalid pdf" do
          subject(:record) { model.public_send(attribute).attach(pdf_200x300_file) and model }

          let(:attribute) { :with_pdf_file }
          let(:error_options) do
            {
              length: 150,
              filename: "pdf_200x300_file.pdf"
            }
          end

          it { is_expected_not_to_be_valid }
          it { is_expected_to_include_error_message("dimension_width_not_equal_to", error_options: error_options) }
          it { is_expected_to_include_error_message("dimension_height_not_equal_to", error_options: error_options) }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end
  end

  describe "Blob Metadata" do
    let(:attachable) do
      {
        io: open_fixture(Rails.root.join("public", "image_150x150.png")),
        filename: "image_150x150.png",
        content_type: "image/png"
      }
    end

    it_behaves_like "is performance optimized"
  end

  describe "Rails options" do
    it_behaves_like "works with all rails common validation options"
  end
end
