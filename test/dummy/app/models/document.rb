class Document < ApplicationRecord
  has_one_attached :attachment
  has_one_attached :file

  validates :attachment, content_type: %i[docx xlsx pages numbers]
  validates :file, content_type: :tar
end
