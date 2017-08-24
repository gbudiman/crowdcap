class CreateGensenStagings < ActiveRecord::Migration[5.1]
  def change
    create_table :gensen_stagings, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.belongs_to             :picture, index: true, type: :bigint, null: false, foreign_key: true
      t.integer                :method, null: false
      t.integer                :confidence_rank, default: 1, null: false
      t.string                 :sentence, null: false
      t.timestamps
    end

    add_index :gensen_stagings, [:picture_id, :method]
    add_index :gensen_stagings, :method
  end
end
