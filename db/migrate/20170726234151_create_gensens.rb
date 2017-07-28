class CreateGensens < ActiveRecord::Migration[5.0]
  def change
    create_table :gensens, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.belongs_to             :picture, index: true, type: :bigint, null: false, foreign_key: true
      t.integer                :method, null: false
      t.string                 :sentence, null: false
      t.timestamps
    end

    add_index :gensens, [:picture_id, :method]
    add_index :gensens, :method
  end
end
