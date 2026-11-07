# frozen_string_literal: true

require "rails_helper"
require "active_storage_validations/matchers"

# A `strict: true` validator raises ActiveModel::StrictValidationFailed instead
# of adding its error, which made every matcher probe raise.
RSpec.describe ActiveStorageValidations::Matchers::ASVValidatable do
  include ActiveStorageValidations::Matchers

  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = "size_matchers"
      def self.name = "StrictValidationsMatcherProbe"

      has_one_attached :avatar
      has_many_attached :photos
      validates :title, presence: true, strict: true
      validates :avatar, attached: true, size: { less_than: 2.kilobytes }, content_type: :png, strict: true
      validates :photos, limit: { max: 2 }, dimension: { width: { max: 800 } }, strict: true
    end
  end

  describe "matchers on an attribute with strict validators" do
    it { expect(validate_attached_of(:avatar).matches?(klass)).to be(true) }
    it { expect(validate_size_of(:avatar).less_than(2.kilobytes).matches?(klass)).to be(true) }
    it { expect(validate_size_of(:avatar).less_than(3.kilobytes).matches?(klass)).to be(false) }
    it { expect(validate_content_type_of(:avatar).allowing(:png).rejecting(:gif).matches?(klass)).to be(true) }
    it { expect(validate_limits_of(:photos).max(2).matches?(klass)).to be(true) }
    it { expect(validate_dimensions_of(:photos).width_max(800).matches?(klass)).to be(true) }
  end

  describe "validations outside the matcher" do
    it "still raise" do
      record = klass.new(title: "Title")
      record.avatar.attach(io: StringIO.new("a" * 3.kilobytes), filename: "avatar.png", content_type: "image/png")

      validate_size_of(:avatar).less_than(2.kilobytes).matches?(klass)

      expect { record.valid? }.to raise_error(ActiveModel::StrictValidationFailed)
    end
  end
end
