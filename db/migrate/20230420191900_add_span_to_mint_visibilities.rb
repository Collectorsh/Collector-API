class AddSpanToMintVisibilities < ActiveRecord::Migration[6.1]
  def change
    add_column :mint_visibilities, :span, :integer, default: 1
  end
end
