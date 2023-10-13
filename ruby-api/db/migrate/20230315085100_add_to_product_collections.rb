class AddToProductCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :product_collections, :wallet, :string
    add_column :product_collections, :email, :string
  end
end
