class AddCocoInternalIDtoMergedCaption < ActiveRecord::Migration[5.0]
  def change
    add_column :merged_captions, :coco_internal_id, :bigint
  end
end
