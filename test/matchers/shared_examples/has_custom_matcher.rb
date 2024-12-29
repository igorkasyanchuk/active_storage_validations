module HasCustomMatcher
  extend ActiveSupport::Concern

  included do
    let(:model_attribute) { :custom_matcher }

    describe 'using custom matcher' do
      before do
        class ActiveSupport::TestCase
          extend ActiveStorageValidations::Matchers
        end

        case validator_sym
        when :aspect_ratio then custom_matcher_builder.validate_aspect_ratio_of(model_attribute).allowing(:square)
        when :attached then custom_matcher_builder.validate_attached_of(model_attribute)
        when :processable_file then custom_matcher_builder.validate_processable_file_of(model_attribute)
        when :limit then custom_matcher_builder.validate_limits_of(model_attribute).min(1).max(5)
        when :content_type then custom_matcher_builder.validate_content_type_of(model_attribute).allowing('image/png')
        when :dimension then custom_matcher_builder.validate_dimensions_of(model_attribute).width(150).height(150)
        when :size then custom_matcher_builder.validate_size_of(model_attribute).less_than_or_equal_to(5.megabytes)
        when :total_size then custom_matcher_builder.validate_total_size_of(model_attribute).less_than_or_equal_to(5.megabytes)
        end
      end

      subject { matcher } # to be able to use validator_sym method

      let(:custom_matcher_builder) { ActiveSupport::TestCase }

      it 'makes the method available for use' do
        refute(custom_matcher_builder.nil?)
      end
    end
  end
end
