class RatioModel < ApplicationRecord
  validates :name, presence: true
  has_one_attached :ratio_one
  has_many_attached :ratio_many
  has_one_attached :image1
  has_one_attached :proc_ratio_one
  has_many_attached :proc_ratio_many
  has_one_attached :proc_image1
  has_one_attached :portrait_image
  has_one_attached :landscape_image
  has_one_attached :squared_image
  has_one_attached :widescreen_image

  validates :ratio_one, attached: true, aspect_ratio: :square
  validates :ratio_many, attached: true, aspect_ratio: :portrait # portrait
  validates :image1, aspect_ratio: :is_16_9 # portrait

  validates :portrait_image, aspect_ratio: :portrait
  validates :landscape_image, aspect_ratio: :landscape
  validates :squared_image, aspect_ratio: :square
  validates :widescreen_image, aspect_ratio: :is_16_9square

  #validates :ratio_many, attached: true, aspect_ratio: :landscape
  #validates :ratio_many, attached: true, aspect_ratio: :portrait # portrait
  validates :proc_ratio_one, attached: true, aspect_ratio: -> (record) {:square}
  validates :proc_ratio_many, attached: true, aspect_ratio: -> (record) {:portrait} # portrait
  validates :proc_image1, aspect_ratio: -> (record) {:is_16_9} # portrait
end
