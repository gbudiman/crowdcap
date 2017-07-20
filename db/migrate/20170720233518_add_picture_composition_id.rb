class AddPictureCompositionId < ActiveRecord::Migration[5.0]
  def change
    add_column :pictures, :composition_id, :bigint
    add_index :pictures, :composition_id
  end
end
