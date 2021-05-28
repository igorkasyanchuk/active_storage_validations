class InvalidContentType < ApplicationRecord
  has_one_attached :document

  validates :document, content_type: %i[txt doc]
end
