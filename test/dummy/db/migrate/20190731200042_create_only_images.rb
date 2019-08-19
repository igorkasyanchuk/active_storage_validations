class CreateOnlyImages < ActiveRecord::Migration[5.2]
  def change
    create_table :only_images do |t|

      t.timestamps
    end
  end
end
