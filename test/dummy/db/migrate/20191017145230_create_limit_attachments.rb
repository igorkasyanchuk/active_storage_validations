class CreateLimitAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :limit_attachments do |t|
      t.string :name
    end
  end
end
