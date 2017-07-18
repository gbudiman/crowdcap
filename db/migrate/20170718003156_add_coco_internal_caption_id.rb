class AddCocoInternalCaptionId < ActiveRecord::Migration[5.0]
  def change
    add_column :captions, :coco_internal_id, :bigint
  end
end
