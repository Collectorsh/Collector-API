class CreateSales < ActiveRecord::Migration[6.1]
  def change
    create_table :sales do |t|
      t.belongs_to :user
      t.integer :end_time, limit: 5
      t.integer :highest_bid, limit: 5
      t.integer :number_of_bids
      t.string :mint
      t.string :name
      t.string :brand_name
      t.string :collection_name
      t.string :image
      t.string :source
      t.string :metadata_uri
      t.timestamps
    end
    add_index :sales, :end_time
    add_index :sales, :brand_name
    add_index :sales, :mint
  end
end
