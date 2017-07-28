class CreateSubvals < ActiveRecord::Migration[5.0]
  def change
    create_table :subvals, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.bigint                 :a_id, null: false
      t.bigint                 :b_id, null: false
      t.timestamps
    end
  end
end
