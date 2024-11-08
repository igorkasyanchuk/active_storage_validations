module WorksFineWithAttachables
  extend ActiveSupport::Concern

  included do
    describe "works fine with attachables" do
      subject { validator_test_class::UsingAttachable.new(params) }

      let(:model) { validator_test_class::UsingAttachable.new(params) }
      let(:validator_class) { "ActiveStorageValidations::#{validator_test_class.name.delete('::')}".constantize }

      let(:png_image) { Rails.root.join('public', 'image_150x150.png') }

      describe "working with all attachable formats" do
        # As stated in ActiveStorage documentation, attachables can either be a:
        #   ActiveStorage::Blob object
        #   ActionDispatch::Http::UploadedFile object
        #   Rack::Test::UploadedFile object
        #   Hash object representing the io / filename / content_type
        #   String object representing the signed reference to blob
        #   File object
        #   Pathname object

        %w(one many).each do |relationship_type|
          describe relationship_type do
            let(:attribute) { :"using_attachable#{'s' if relationship_type == 'many'}" }
            let(:attachables) do
              relationship_type == 'one' ? attachable : [attachable, attachable]
            end

            describe "ActiveStorage::Blob object" do
              subject { model.public_send(attribute).attach(attachables) and model }

              let(:attachable) do
                ActiveStorage::Blob.create_and_upload!(
                  io: File.open(png_image),
                  filename: 'image_150x150.png',
                  content_type: 'image/png',
                  service_name: 'test'
                )
              end

              it { is_expected_to_be_valid }
            end

            describe "ActionDispatch::Http::UploadedFile object" do
              subject { model.public_send(attribute).attach(attachables) and model }

              let(:attachable) do
                tempfile = Tempfile.new(['image_150x150', '.png'])
                tempfile.write(File.read(png_image))
                tempfile.rewind

                ActionDispatch::Http::UploadedFile.new({
                  tempfile: tempfile,
                  filename: 'image_150x150.png',
                  type: 'image/png'
                })
              end

              it { is_expected_to_be_valid }
            end

            describe "Rack::Test::UploadedFile object" do
              subject { model.public_send(attribute).attach(attachables) and model }

              let(:attachable) { Rack::Test::UploadedFile.new(png_image, 'image/png') }

              it { is_expected_to_be_valid }
            end

            describe "Hash object representing the io / filename / content_type" do
              subject { model.public_send(attribute).attach(attachables) and model }

              let(:attachable) do
                {
                  io: File.open(png_image),
                  filename: 'image_150x150.png',
                  content_type: 'image/png'
                }
              end

              it { is_expected_to_be_valid }
            end

            describe "String object representing the signed reference to blob" do
              subject { model.public_send(attribute).attach(attachables) and model }

              let(:attachable) do
                blob = ActiveStorage::Blob.create_and_upload!(
                  io: File.open(png_image),
                  filename: 'image_150x150.png',
                  content_type: 'image/png',
                  service_name: 'test'
                )
                blob.signed_id
              end

              it { is_expected_to_be_valid }
            end

            describe "File object" do
              subject { model.public_send(attribute).attach(attachable) and model }

              let(:attachable) { File.open(png_image) }

              if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
                it { is_expected_to_be_valid }
              else
                it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
              end
            end

            describe "Pathname object" do
              subject { model.public_send(attribute).attach(attachable) and model }

              let(:attachable) { Pathname.new(png_image) }

              if Rails.gem_version >= Gem::Version.new('7.1.0.rc1')
                it { is_expected_to_be_valid }
              else
                it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{attachable.inspect}") }
              end
            end

            describe "something else" do
              subject { model.public_send(attribute).attach(wrong_representation) and model }

              let(:wrong_representation) { 42 }

              it { is_expected_to_raise_error(ArgumentError, "Could not find or build blob: expected attachable, got #{wrong_representation.inspect}") }
            end
          end
        end
      end

      describe "when there are no attachments" do
        it { is_expected_to_be_valid }

        it "does not perform any validation" do
          validator_class.stub_any_instance(:is_valid?, -> { raise "shouldn't be called" }) do
            subject.valid?
          end
        end
      end

      describe "when several passed files are the same file" do
        let(:attachable) do
          {
            io: File.open(png_image),
            filename: 'image_150x150.png',
            content_type: 'image/png'
          }
        end

        before { subject.using_attachables.attach([attachable, attachable]) }

        it "only performs the validation once for these files" do
          assert_called_on_instance_of(validator_class, :is_valid?, times: 1) do
            subject.valid?
          end
        end
      end

      describe "when doing an update" do
        before do
          subject.using_attachables.attach(attachable_1)
          subject.save!
        end

        let(:attachable_1) do
          {
            io: File.open(png_image),
            filename: 'image_150x150.png',
            content_type: 'image/png'
          }
        end
        let(:attachable_2) do
          ActiveStorage::Blob.create_and_upload!(
            io: File.open(png_image),
            filename: 'image_150x150.png',
            content_type: 'image/png',
            service_name: 'test'
          )
        end

        it "updates the attribute accordingly and does not break" do
          subject.using_attachables.attach(attachable_2)
          subject.save!
          assert(subject.valid?)
        end
      end
    end
  end
end
