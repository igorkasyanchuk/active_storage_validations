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
  has_many_attached :photo_with_messages
  has_one_attached :image_regex
  has_one_attached :conditional_image
  has_one_attached :conditional_image_2
  has_one_attached :moon_picture
  has_one_attached :proc_avatar
  has_many_attached :proc_photos
  has_many_attached :proc_photo_with_messages
  has_one_attached :proc_image_regex

  validates :name, presence: true

  validates :avatar, attached: { message: "must not be blank" }, content_type: :png
  validates :photos, attached: true, content_type: ['image/png', 'image/jpeg', /\A.*\/pdf\z/]
  validates :photo_with_messages, content_type: { in: ['image/png', 'image/jpeg', /\A.*\/pdf\z/], message: "must be an authorized type" }
  validates :image_regex, content_type: /\Aimage\/.*\z/
  validates :conditional_image, attached: true, if: -> { name == 'Foo' }
  validates :conditional_image_2, attached: true, content_type: -> (record) {[/\Aimage\/.*\z/]}, size: { less_than: 10.megabytes }, if: -> { name == 'Peter Griffin' }

  validates :moon_picture, content_type: ['image/png'], size: { greater_than: 0 }

  validates :proc_avatar, attached: { message: "must not be blank" }, content_type: -> (record) {:png}
  validates :proc_photos, attached: true, content_type: -> (record) {['image/png', 'image/jpeg', /\A.*\/pdf\z/]}
  validates :proc_photo_with_messages, content_type: { in: -> (record) {['image/png', 'image/jpeg', /\A.*\/pdf\z/]}, message: "must be an authorized type" }
  validates :proc_image_regex, content_type: -> (record) {/\Aimage\/.*\z/}
  validates :proc_image_regex, content_type: -> (record) {/\Aimage\/.*\z/}
end
