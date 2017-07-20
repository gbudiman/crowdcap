class CreateCompositions < ActiveRecord::Migration[5.0]
  def change
    create_table :compositions, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.integer                :contents, array: true
      t.string                 :content_textual, array: true
      t.timestamps
    end

    add_index :compositions, :contents, using: 'gin'
  end
end
