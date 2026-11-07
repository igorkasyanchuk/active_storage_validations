# frozen_string_literal: true

require "rails_helper"

# A blob attached before its validator existed has no asv_* cache yet: the
# next valid? analyzes it and saves the result on the blob, which a reading
# role (automatic role switching on GET requests) does not allow.
RSpec.describe "validating while writes are prevented" do
  # validates :width_max, dimension: { width: { max: 500 } }
  subject(:record) { Dimension::Validator::Check.find(seeded.id) }

  let!(:seeded) do
    Dimension::Validator::Check.new.tap do |model|
      model.width_max.attach(image_700x500_file)
      model.save!(validate: false)
    end
  end

  it "validates with the analysis kept in memory instead of raising" do
    result = ActiveRecord::Base.while_preventing_writes { record.valid? }

    expect(result).to be(false)
    expect(record.errors.details[:width_max].pluck(:error)).to eq([ :dimension_width_not_less_than_or_equal_to ])
  end
end
