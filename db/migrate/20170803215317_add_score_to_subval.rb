class AddScoreToSubval < ActiveRecord::Migration[5.0]
  def change
    add_column                 :subvals, :score, :integer, null: false
  end
end
