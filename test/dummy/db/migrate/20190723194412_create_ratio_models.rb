class CreateRatioModels < ActiveRecord::Migration[5.2]
  def change
    create_table :ratio_models do |t|
      t.string :name

      t.timestamps
    end
  end
end
