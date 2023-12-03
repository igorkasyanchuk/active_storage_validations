module WorksWithUnlessOption
  extend ActiveSupport::Concern

  included do
    subject { validator_test_class::WithUnless.new(params) }

    let(:file_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_150x150_file
      when :attached then image_150x150_file
      when :content_type then webp_file
      when :dimension then image_150x150_file
      when :limit then image_150x150_file
      when :processable_image then image_150x150_file
      when :size then file_1ko
      end
    end
    let(:file_not_matching_requirements) do
      case validator_sym
      when :aspect_ratio then image_700x500_file
      when :attached then nil
      when :content_type then html_file
      when :dimension then image_700x500_file
      when :limit then nil
      when :processable_image then tar_file_with_image_content_type
      when :size then file_5ko
      end
    end

    describe 'when the :unless condition is a method' do
      describe 'and the condition is not met' do
        # Here 0 is important to only trigger the #with_unless attribute
        let(:params) { { rating: 0 } }

        describe 'and when passed a file matching the requirements' do
          before { subject.with_unless.attach(file_matching_requirements) }

          it { is_expected_to_be_valid }
        end

        describe 'and when passed a file not matching the requirements' do
          let(:error_options) { { unless: :rating_is_good? } }

          before { subject.with_unless.attach(file_not_matching_requirements) }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end

    describe 'when the :unless condition is a Proc' do
      describe 'and the condition is not met' do
         # Here 4 is important to only trigger the #with_unless_proc attribute
        let(:params) { { rating: 4 } }

        describe 'and when passed a file matching the requirements' do
          before { subject.with_unless_proc.attach(file_matching_requirements) }

          it { is_expected_to_be_valid }
        end

        describe 'and when passed a file not matching the requirements' do
          let(:error_options) { { unless: -> { self.rating == 0 } } }

          before { subject.with_unless_proc.attach(file_not_matching_requirements) }

          it { is_expected_not_to_be_valid }
          it { is_expected_to_have_error_options(error_options) }
        end
      end
    end
  end
end
