class CreateMergedCaptions < ActiveRecord::Migration[5.0]
  def change
    create_table :merged_captions, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.text                   :caption, null: false
      t.belongs_to             :picture, index: true, type: :bigint, null: false, foreign_key: true
      t.timestamps
    end
  end
end
