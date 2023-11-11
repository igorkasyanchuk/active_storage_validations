class Video < ApplicationRecord
  has_one_attached :video

  validates :video, dimension: { width: { min: 10, max: 20 }, height: { min: 10, max: 20 } },
                    aspect_ratio: :is_16_9,
                    content_type: ['video/x-msvideo', 'video/mp4']
end
