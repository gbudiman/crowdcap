class CreatePotentials < ActiveRecord::Migration[5.0]
  def change
    create_table :potentials, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.bigint                 :query_id, null: false
      t.bigint                 :target_id, null: false
      t.integer                :count_evaluated, default: 0, null: false
      t.integer                :count_correct, default: 0, null: false
      t.timestamps
    end

    add_index :potentials, [:query_id, :target_id], unique: true
    add_foreign_key :potentials, :pictures, column: :query_id, name: :fk_query_picture
    add_foreign_key :potentials, :pictures, column: :target_id, name: :fk_target_picture
  end
end
