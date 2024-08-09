class Metadata < ApplicationRecord
  has_one_attached :large_image

  validates :large_image, processable_image: true
end
