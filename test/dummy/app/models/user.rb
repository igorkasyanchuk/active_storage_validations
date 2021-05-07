# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :photos
  has_one_attached :image_regex
  has_one_attached :conditional_image

  validates :name, presence: true

  validates :avatar, attached: true, content_type: :png
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg', /\A.*\/pdf\z/]
  validates :image_regex, content_type: /\Aimage\/.*\z/
  validates :conditional_image, attached: true, if: -> { name == 'Foo' }
end
