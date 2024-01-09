class CreateCurationListings < ActiveRecord::Migration[6.1]
  def change
    create_table :curation_listings do |t|
      t.string :mint, null: false
      t.integer :curation_id, null: false
      t.string :name, null: false
      t.integer :owner_id
      t.string :owner_address, null: false
      t.numeric :buy_now_price
      t.string :listed_status, default: 'unlisted'
      t.integer :artist_id
      t.string :artist_address, null: false
      t.numeric :aspect_ratio
      t.string :animation_url
      t.string :image
      t.string :description
      t.string :listing_receipt
      t.boolean :primary_sale_happened
      t.boolean :is_edition, default: false
      t.string :parent 
      t.boolean :is_master_edition, default: false
      t.integer :supply
      t.integer :max_supply
      t.string :master_edition_market_address
      t.json :creators
      t.json :files
      t.string :nft_state
      t.string :temp_artist_name

      t.timestamps
    end

    add_index :curation_listings, [:curation_id, :mint], unique: true
    add_foreign_key :curation_listings, :users, column: :artist_id
    add_foreign_key :curation_listings, :users, column: :owner_id
    add_foreign_key :curation_listings, :curations, column: :curation_id
  end
end
