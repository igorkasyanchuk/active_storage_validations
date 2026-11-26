# frozen_string_literal: true

# validates :with_message_placeholders, <validator>: { …, message: "… %{bound} … %{measured value}" }
RSpec.shared_examples "interpolates custom message placeholders" do
  describe "custom message placeholders" do
    subject(:model) { validator_test_class::WithMessage.new(params) }

    let(:messages) { model.errors.messages_for(:with_message_placeholders) }

    around { |example| I18n.with_locale(:en) { example.run } }

    context "when the file cannot be analyzed" do
      before { model.with_message_placeholders.attach(empty_io_file) }

      it "shows the bounds and leaves the measured value blank instead of raising" do
        model.valid?

        expect(messages).to eq([ message_for_unanalyzable_file ])
      end
    end

    context "when the file does not match the requirements" do
      before { model.with_message_placeholders.attach(file_not_matching_placeholders) }

      it "shows every value" do
        model.valid?

        expect(messages).to eq([ message_for_file_not_matching ])
      end
    end
  end
end
