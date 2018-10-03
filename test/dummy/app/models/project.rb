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
  has_one_attached :small_file

  validates :title, presence: true

  validates :preview, attached: true, size: { greater_than: 1.kilobytes }
  validates :attachment, attached: true, content_type: { in: 'application/pdf', message: 'is not a PDF' } , size: { between: 0..500.kilobytes , message: 'is not given between size' }
  validates :small_file, attached: true , size: { less_than: 1.kilobytes }
end
