class AddPictureMetadata < ActiveRecord::Migration[5.0]
  def change
    add_column :pictures, :coco_internal_id, :bigint
    add_column :pictures, :height, :integer
    add_column :pictures, :width, :integer
  end
end
