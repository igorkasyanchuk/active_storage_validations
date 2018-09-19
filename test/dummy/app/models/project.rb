# == Schema Information
#
# Table name: projects
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Project < ApplicationRecord
  has_one_attached :preview
  has_one_attached :attachment

  validates :title, presence: true

  validates :preview, attached: true ,content_size: { greater_than: 100.kilobytes }
  validates :attachment, attached: true, content_type: { in: 'application/pdf', message: 'is not a PDF' } , content_size: { between: 0..10.megabytes , message: 'is not given between size' }
end
