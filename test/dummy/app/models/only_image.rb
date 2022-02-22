class OnlyImage < ApplicationRecord
  has_one_attached :image
  validates :image, dimension: { width: { min: 100, max: 2000 }, height: { min: 100, max: 1500 } },
                    aspect_ratio: :is_16_9,
                    content_type: ['image/png', 'image/jpeg']
end
