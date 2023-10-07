class CreateProductMintList < ActiveRecord::Migration[6.1]
  def change
    create_table :product_mint_lists do |t|
      t.string :name
      t.string :mint
      t.timestamps
    end
  end
end
