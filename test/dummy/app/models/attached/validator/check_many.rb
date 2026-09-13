# frozen_string_literal: true

# Reuses attached_validator_checks; only the attachments name differs from Check.
class Attached::Validator::CheckMany < ApplicationRecord
  self.table_name = "attached_validator_checks"

  has_many_attached :has_to_be_attached_many
  validates :has_to_be_attached_many, attached: true
end
