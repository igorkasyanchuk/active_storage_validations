class RatioModel < ApplicationRecord
  validates :name, presence: true
  has_one_attached :ratio_one
  has_many_attached :ratio_many
  has_one_attached :image1

  validates :ratio_one, attached: true, aspect_ratio: :square
  validates :ratio_many, attached: true, aspect_ratio: :portrait # portrait
  validates :image1, aspect_ratio: :is_16_9 # portrait
  #validates :ratio_many, attached: true, aspect_ratio: :landscape
  #validates :ratio_many, attached: true, aspect_ratio: :portrait # portrait
end
