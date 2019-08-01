class CreateOnlyImages < ActiveRecord::Migration[6.0]
  def change
    create_table :only_images do |t|

      t.timestamps
    end
  end
end
