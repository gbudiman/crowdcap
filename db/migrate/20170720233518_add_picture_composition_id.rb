class AddPictureCompositionId < ActiveRecord::Migration[5.0]
  def change
    add_column :pictures, :picture_composition_id, :bigint
    add_index :pictures, :picture_composition_id
  end
end
