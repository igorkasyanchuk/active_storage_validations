# frozen_string_literal: true

RSpec.shared_examples "works with both instance and class" do
  context "when provided with the other validator requirements" do
    before do
      case validator_sym
      when :aspect_ratio then matcher.allowing(:square)
      when :attached then nil
      when :processable_file then nil
      when :limit then matcher.min(1).max(5)
      when :content_type then matcher.allowing("image/png")
      when :dimension then matcher.width(150).height(150)
      when :duration then matcher.less_than_or_equal_to(5.minutes)
      when :with_audio then nil
      when :size then matcher.less_than_or_equal_to(5.megabytes)
      when :total_size then matcher.less_than_or_equal_to(5.megabytes)
      when :pages then matcher.less_than_or_equal_to(5)
      end
    end

    let(:model_attribute) { :as_instance }
    let(:file) { { io: StringIO.new("file"), filename: "file.png", content_type: "image/png" } }

    context "when the matcher is provided with an instance" do
      subject(:configured_matcher) { matcher }

      let(:instance) { klass.new }

      it { is_expected_to_match_for(instance) }

      context "which has a pending attachment" do
        before { instance.public_send(model_attribute).attach(file) }

        it "keeps the instance attachment" do
          configured_matcher.matches?(instance)

          expect(instance.attachment_changes).to have_key(model_attribute.to_s)
        end
      end
    end

    # The probes attach files: on a persisted record, `attach` saves them.
    context "when the matcher is provided with a persisted instance" do
      subject(:configured_matcher) { matcher }

      let(:instance) { klass.new.tap { |record| record.save!(validate: false) } }

      it { is_expected_to_match_for(instance) }

      it "does not save any probe attachment" do
        expect { configured_matcher.matches?(instance) }.not_to change(ActiveStorage::Attachment, :count)
        expect(instance.reload.public_send(model_attribute)).not_to be_attached
      end

      context "which has an attached file" do
        # The dummy file does not pass every validator, so skip validation.
        before do
          instance.public_send(model_attribute).attach(file)
          instance.save!(validate: false)
        end

        it "keeps the instance attachment" do
          expect { configured_matcher.matches?(instance) }.not_to change(ActiveStorage::Attachment, :count)
          expect(instance.reload.public_send(model_attribute)).to be_attached
        end
      end
    end
  end
end
