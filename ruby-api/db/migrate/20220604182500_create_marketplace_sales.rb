class CreateMarketplaceSales < ActiveRecord::Migration[6.1]
  def change
    create_table :marketplace_sales do |t|
      t.integer :timestamp, limit: 5
      t.integer :user_id
      t.string :formfunction_username
      t.string :artist_name
      t.string :name
      t.string :brand_name
      t.string :collection_name
      t.string :marketplace
      t.string :mint
      t.string :twitter
      t.integer :amount, limit: 5
      t.string :image
      t.string :buyer
      t.string :seller
      t.string :signature
      t.string :creator
      t.timestamps
    end
    add_index :marketplace_sales, :timestamp
    add_index :marketplace_sales, :artist_name
    add_index :marketplace_sales, :user_id
    add_index :marketplace_sales, :mint
  end
end
