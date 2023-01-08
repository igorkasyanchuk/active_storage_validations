class Document < ApplicationRecord
  has_one_attached :attachment
  has_one_attached :file
  has_one_attached :proc_attachment
  has_one_attached :proc_file

  validates :attachment, content_type: %i[docx xlsx pages numbers]
  validates :file, content_type: :tar
  validates :proc_attachment, content_type: -> (record) {%i[docx xlsx pages numbers]}
  validates :proc_file, content_type: -> (record) {:tar}
end
