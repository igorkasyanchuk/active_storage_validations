class LimitAttachment < ApplicationRecord
  has_many_attached :files
  validates :files, limit: { max: 4 }
end
