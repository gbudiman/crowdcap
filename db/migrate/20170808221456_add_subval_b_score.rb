class AddSubvalBScore < ActiveRecord::Migration[5.0]
  def change
    rename_column :subvals, :score, :a_score
    add_column :subvals, :b_score, :integer, null: false
  end
end
