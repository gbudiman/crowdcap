class AddGensenConfidenceRank < ActiveRecord::Migration[5.1]
  def change
    add_column :gensens, :confidence_rank, :integer, null: false, default: 1
  end
end
