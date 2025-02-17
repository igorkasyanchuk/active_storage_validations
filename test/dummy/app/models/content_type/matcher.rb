# frozen_string_literal: true

# == Schema Information
#
# Table name: content_type_matchers
#
#  title      :string
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ContentType::Matcher < ApplicationRecord
  include Validatable

  has_one_attached :custom_matcher
  validates :custom_matcher, content_type: [ "image/png" ]

  has_one_attached :allowing_one
  validates :allowing_one, content_type: :png
  has_one_attached :allowing_several
  validates :allowing_several, content_type: [ "image/png", "image/gif" ]
  has_one_attached :allowing_several_through_regex
  validates :allowing_several_through_regex, content_type: [ /\Aimage\/.*\z/ ]

  has_one_attached :allowing_symbol
  validates :allowing_symbol, content_type: :png
  has_one_attached :allowing_sneaky_edge_cases
  validates :allowing_sneaky_edge_cases, content_type: [ "image/svg+xml", "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ]

  has_one_attached :allow_blank
  validates :allow_blank, content_type: [ "image/png" ], allow_blank: true

  has_one_attached :with_message
  validates :with_message, content_type: { in: [ "image/png" ], message: "Custom message" }

  has_one_attached :with_context_symbol
  validates :with_context_symbol, content_type: :png, on: :update
  has_one_attached :with_context_array
  validates :with_context_array, content_type: :png, on: %i[update custom]
  has_one_attached :with_several_validators_and_contexts
  validates :with_several_validators_and_contexts, content_type: :png, on: :update
  validates :with_several_validators_and_contexts, content_type: :png, on: :custom

  has_one_attached :as_instance
  validates :as_instance, content_type: :png

  has_one_attached :validatable_different_error_messages
  validates :validatable_different_error_messages, content_type: { with: :pdf, message: "Custom message 1" }, if: :title_is_quo_vadis?
  validates :validatable_different_error_messages, content_type: { with: :png, message: "Custom message 2" }, if: :title_is_american_psycho?

  has_one_attached :failure_message
  validates :failure_message, content_type: :png
  has_one_attached :failure_message_when_negated
  validates :failure_message_when_negated, content_type: :png

  # Combinations
  has_one_attached :allowing_one_with_message
  validates :allowing_one_with_message, content_type: { in: [ "application/pdf" ], message: "Not authorized file type." }

  most_common_mime_types.reject { |common_mime_type| common_mime_type[:type] == :ogv } # issue with ogv
                        .each do |content_type|
    has_one_attached :"#{content_type[:media]}_#{content_type[:type]}"
    validates :"#{content_type[:media]}_#{content_type[:type]}",
              content_type: content_type[:type]
  end
  has_one_attached :video_ogv
  validates :video_ogv, content_type: [ "video/theora" ]
end
