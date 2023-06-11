class AddUniqueIndexToMintVisibilities < ActiveRecord::Migration[6.1]
  def change
    add_index :mint_visibilities, [:user_id, :mint_address], unique: true
  end
end