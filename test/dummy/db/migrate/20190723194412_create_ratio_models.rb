class CreateRatioModels < ActiveRecord::Migration[6.0]
  def change
    create_table :ratio_models do |t|
      t.string :name

      t.timestamps
    end
  end
end
