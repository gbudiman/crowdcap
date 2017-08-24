class CreateCachedDomains < ActiveRecord::Migration[5.1]
  def change
    create_table :cached_domains, id: false do |t|
      t.bigserial              :id, primary_key: true
      t.integer                :domain_id, index: true, null: false
      t.belongs_to             :picture, index: true, type: :bigint, null: false
      t.timestamps
    end
  end
end
