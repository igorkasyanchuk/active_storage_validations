class OnlyImage < ApplicationRecord
  has_one_attached :image
  has_one_attached :proc_image
  has_one_attached :another_image
  has_one_attached :any_image

  validates :image, dimension: { width: { min: 100, max: 2000 }, height: { min: 100, max: 1500 } },
                    aspect_ratio: :is_16_9,
                    content_type: ['image/png', 'image/jpeg']
  validates :proc_image, dimension: { width: { min: -> (record) {100}, max: -> (record) {2000} }, height: { min: -> (record) {100}, max: -> (record) {1500} } },
            aspect_ratio: -> (record) {:is_16_9},
            content_type: -> (record) {['image/png', 'image/jpeg']}
  validates :another_image, processable_file: true
  validates :any_image, processable_file: false
end
