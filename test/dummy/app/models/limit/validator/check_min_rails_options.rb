# frozen_string_literal: true

# == Schema Information
#
# Table name: limit_validator_check_min_rails_options
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# `min:` is the one check that fails without files, so it shows whether
# :allow_blank / :allow_nil skip an attribute without files.
class Limit::Validator::CheckMinRailsOptions < ApplicationRecord
  {
    without_option: {},
    allow_blank: { allow_blank: true },
    not_allow_blank: { allow_blank: false },
    allow_nil: { allow_nil: true }
  }.each do |name, rails_options|
    has_many_attached :"#{name}_many"
    validates :"#{name}_many", limit: { min: 1 }, **rails_options

    has_one_attached :"#{name}_one"
    validates :"#{name}_one", limit: { min: 1 }, **rails_options
  end

  # Rails 8.2+ accepts a Proc; earlier versions read any Proc as truthy.
  if ActiveModel::EachValidator.private_method_defined?(:allow_blank?)
    has_many_attached :allow_blank_proc_many
    validates :allow_blank_proc_many, limit: { min: 1 }, allow_blank: ->(record) { record.title == "Draft" }
  end
end
