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

  validates :name, presence: true

  validates :avatar, attached: true, content_type: 'image/png'
  validates :photos, attached: true, content_type: ['image/png', 'image/jpg']
end
