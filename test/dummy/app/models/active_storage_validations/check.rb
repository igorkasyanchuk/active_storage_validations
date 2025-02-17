# frozen_string_literal: true

# == Schema Information
#
# Table name: active_storage_validations_checks
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ActiveStorageValidations::Check < ApplicationRecord
  self.table_name = "active_storage_validations_checks"

  # This include is related to a test to ensure that the gem's module do not
  # override the clien'ts concerns
  include Attachable

  # This validator is related to a test to ensure that the developer can define
  # its own custom mime types
  has_one_attached :asv_test
  validates :asv_test, content_type: "application/asv_test"

  # We ensure that the gem is working fine when using fixtures
  has_one_attached :working_with_fixture
  validates :working_with_fixture, content_type: "image/png"

  # We ensure that the gem is working fine when using fixtures + variant
  has_one_attached :working_with_fixture_and_variant do |attachable|
    attachable.variant :medium, resize_to_fill: [ 800, 400 ], preprocessed: true
  end
  validates :working_with_fixture_and_variant, content_type: "image/png"
end
