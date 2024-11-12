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
end
