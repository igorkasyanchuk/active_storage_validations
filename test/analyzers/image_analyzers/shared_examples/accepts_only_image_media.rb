# frozen_string_literal: true

module AcceptsOnlyImageMedia
  extend ActiveSupport::Concern

  included do
    describe ".accept?" do
      it "accepts an image" do
        assert(analyzer_klass.accept?(image_150x150_file))
      end
  
      it "does not accept a non-image" do
        refute(analyzer_klass.accept?(bad_dummy_file))
      end
    end
  end
end
