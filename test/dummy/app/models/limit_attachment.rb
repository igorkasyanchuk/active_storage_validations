class LimitAttachment < ApplicationRecord
  has_many_attached :files
  has_many_attached :proc_files
  validates :files, limit: { max: 4 }
  validates :proc_files, limit: { max: -> (record) {4} }
end
